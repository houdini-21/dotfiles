#!/usr/bin/env python3
"""Phone upgrade price watch (Fernando) — baseline 2026-10-06, target Black Friday 2026-11-27.

Reads live local prices (La Curacao SV, RadioShack SV, waps.sv, Xiaomi Store SV) and evaluates
buy thresholds for the candidate SKUs.

Two consumers:
  * systemd user timer  -> `--notify` (desktop notification via notify-send; the real alert path)
  * Hermes cron monitor -> plain stdout, deterministic (no timestamps) so it gates the job

State: ~/.hermes/price-watches/phone-upgrade-2026.json   Log: same dir, .log

Why headless Chrome: the Magento storefronts 406 any URL carrying a query string from this IP;
a real browser (separate profile) passes. LC serves product data as ld+json, RS as
li.item.product.product-item blocks, waps.sv as JS-rendered cards (offer price + wa.me SKU link).
"""
import json, os, re, subprocess, html, sys, time, fcntl, urllib.parse

BASE = os.path.expanduser("~/.hermes/price-watches/phone-upgrade-2026")
STATE = BASE + ".json"
LOG = BASE + ".log"
LOCK = BASE + ".lock"
PROFILE = os.path.expanduser("~/.cache/phone-watch-chrome")
UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"

# --- targets: (key, threshold_usd, label, store, matcher) -----------------------------
TARGETS = [
    ("XIAOMI_17_512", 999, "Xiaomi 17 12/512", "La Curacao",
     lambda n: n.startswith("Xiaomi 17 ") and "512" in n and "Ultra" not in n and "Combo" not in n),
    ("S25U_256", 899, "Galaxy S25 Ultra 12/256", "waps",
     lambda n: "S25 Ultra" in n and "256" in n),
    ("S26U_256", 1099, "Galaxy S26 Ultra 12/256", "waps",
     lambda n: "S26 Ultra" in n and "256" in n),
    ("X17T_PRO_512", 849, "Xiaomi 17T Pro 12/512", "La Curacao",
     lambda n: n.startswith("Xiaomi 17T Pro") and "512" in n),
]
# contexto: precio visible, sin alerta
CONTEXT = [
    ("COMBO_XIAOMI17_VACUUM", "Combo Xiaomi 17 + aspiradora", lambda n: n.startswith("Combo Xiaomi 17") and "512" in n),
    ("X17_ULTRA_512", "Xiaomi 17 Ultra 16/512", lambda n: n.startswith("Xiaomi 17 Ultra") and "512" in n),
    ("S26_256", "Galaxy S26 12/256 (waps)", lambda n: n.startswith("Samsung S26 Normal") and "256" in n),
    ("S26P_256", "Galaxy S26 Plus 12/256 (waps)", lambda n: n.startswith("Samsung S26 Plus") and "256" in n),
    # para mamá
    ("MOM_RN15_256", "Redmi Note 15 8/256",
     lambda n: n.startswith("Redmi Note 15 ") and "Pro" not in n and "8/256" in n),
    ("MOM_RN15PRO_256", "Redmi Note 15 Pro 8/256",
     lambda n: n.startswith("Redmi Note 15 Pro ") and "8/256" in n),
]
BASE_PRICES = {"XIAOMI_17_512": 1069, "S25U_256": 940, "S26U_256": 1140, "X17T_PRO_512": 969}


# ---------------------------------------------------------------- notify
def resolve_env():
    """systemd no hereda la sesión gráfica: hay que resolverlo igual que alt-reminder.sh."""
    env = dict(os.environ)
    env.setdefault("DISPLAY", ":0")
    if not env.get("DBUS_SESSION_BUS_ADDRESS"):
        env["DBUS_SESSION_BUS_ADDRESS"] = f"unix:path=/run/user/{os.getuid()}/bus"
    return env


def notify(title, msg):
    env = resolve_env()
    try:
        if subprocess.run(["notify-send", "-a", "Alt", "-i", "dialog-information", title, msg],
                          env=env, timeout=15).returncode == 0:
            return True
    except Exception:
        pass
    # fallback: robar la DBUS de un proceso gráfico vivo
    for p in ("polybar", "bspwm", "dunst"):
        try:
            pid = subprocess.run(["pgrep", "-u", str(os.getuid()), "-x", p],
                                 capture_output=True, text=True).stdout.split()
            if not pid:
                continue
            with open(f"/proc/{pid[0]}/environ", "rb") as fh:
                for chunk in fh.read().split(b"\0"):
                    if chunk.startswith(b"DBUS_SESSION_BUS_ADDRESS="):
                        env["DBUS_SESSION_BUS_ADDRESS"] = chunk.split(b"=", 1)[1].decode()
                        return subprocess.run(["notify-send", "-a", "Alt", "-i", "dialog-information",
                                               title, msg], env=env, timeout=15).returncode == 0
        except Exception:
            continue
    return False


def log(line):
    try:
        with open(LOG, "a") as fh:
            fh.write(time.strftime("%Y-%m-%d %H:%M") + "  " + line + "\n")
    except Exception:
        pass


# ---------------------------------------------------------------- scraping
def chrome_dump(url, budget=9000, tries=2):
    for _ in range(tries):
        try:
            r = subprocess.run(
                ["google-chrome-stable", "--headless=new", "--no-sandbox", "--disable-gpu",
                 "--disable-dev-shm-usage", f"--user-data-dir={PROFILE}",
                 f"--virtual-time-budget={budget}", "--dump-dom", url],
                capture_output=True, text=True, timeout=150)
            if r.stdout and len(r.stdout) > 200000:
                return r.stdout
        except Exception:
            pass
        time.sleep(3)
    return ""


def parse_lc(h):
    out = []
    for m in re.finditer(r'<script type="application/ld\+json">(.*?)</script>', h, re.S):
        try:
            data = json.loads(m.group(1))
        except Exception:
            continue
        if not isinstance(data, list):
            data = [data]
        for d in data:
            if isinstance(d, dict) and d.get("@type") == "Product" and "offers" in d:
                off = d["offers"][0] if isinstance(d["offers"], list) else d["offers"]
                out.append({"name": (d.get("name") or "").strip(),
                            "price": off.get("price"),
                            "stock": (off.get("availability") or "").split("/")[-1],
                            "url": d.get("url", ""), "source": "LC"})
    return out


def parse_rs(h):
    out = []
    for b in re.split(r'<li class="item product product-item', h)[1:]:
        m = re.search(r'class="product-item-link"[^>]*href="([^"]+)"[^>]*>(.*?)</a>', b, re.S) \
            or re.search(r'<a[^>]*href="([^"]+)"[^>]*class="product-item-link"[^>]*>(.*?)</a>', b, re.S)
        if not m:
            continue
        name = re.sub(r'\s+', ' ', html.unescape(re.sub(r'<[^>]+>', '', m.group(2))).strip())
        if not name:
            continue
        final = re.findall(r'data-price-type="finalPrice"[^>]*data-price-amount="([\d.]+)"', b) \
            or re.findall(r'data-price-amount="([\d.]+)"[^>]*data-price-type="finalPrice"', b)
        amounts = re.findall(r'data-price-amount="([\d.]+)"', b)
        price = float(final[0]) if final else (min(float(a) for a in amounts) if amounts else None)
        url = m.group(1)
        out.append({"name": name, "price": price, "stock": "AGOTADO" if "AGOTADO" in b else "InStock",
                    "url": url if url.startswith("http") else "https://www.radioshackla.com" + url,
                    "source": "RS"})
    return out


def parse_waps(h):
    """waps.sv: cada tarjeta lleva 'Precio oferta $X' (efectivo/transferencia) y un link de WhatsApp
    con el SKU exacto. Nombre = texto del link; precio = bloque 'Precio oferta' inmediatamente anterior."""
    out = []
    links = list(re.finditer(r'wa\.me/50377449291\?text=([^"\']{5,320})', h))
    prev_end = 0
    for m in links:
        sku = urllib.parse.unquote(html.unescape(m.group(1))).strip()
        if "Quiero visitar" in sku or "Vi el catálogo" in sku:
            prev_end = m.end()
            continue
        seg = h[prev_end:m.start()]
        prev_end = m.end()
        name = re.sub(r'^Hola Waps!\s*[^\s]*\s*Me interesa el\s*', '', sku)
        name = re.sub(r'\.\s*¿Está disponible\?.*$', '', name).strip()
        # el precio de contado (efectivo/transferencia) vive en <div class="price-cash"> … <span class="price-num">1,140.00
        cash = re.findall(r'price-cash">.*?price-num">([\d,]+\.\d{2})', seg, re.S)
        price = float(cash[-1].replace(',', '')) if cash else None
        if price:
            out.append({"name": name, "price": price, "stock": "InStock",
                        "url": "https://waps.sv/", "source": "WAPS"})
    return out


def fetch_all():
    items, pages_ok, pages_fail = [], 0, 0
    bases = [("LC", "https://www.lacuracaonline.com/elsalvador/c/telefonia/celulares-y-telefonos", parse_lc),
             ("RS", "https://www.radioshackla.com/elsalvador/c/telefonia/celulares", parse_rs)]
    for tag, base, parser in bases:
        for p in range(1, 7):
            url = base if p == 1 else f"{base}?p={p}"
            h = chrome_dump(url)
            got = parser(h) if h else []
            if got:
                pages_ok += 1
                items.extend(got)
            else:
                pages_fail += 1
    # waps: catálogo completo renderizado en cliente, una sola página
    h = chrome_dump("https://waps.sv/", budget=13000)
    got = parse_waps(h) if h else []
    if got:
        pages_ok += 1
        items.extend(got)
    else:
        pages_fail += 1
    # tienda oficial Xiaomi (curl basta, sin query string)
    for slug in ["xiaomi-17t-pro", "xiaomi-17-ultra-black-16gb-512gb"]:
        try:
            r = subprocess.run(["curl", "-s", "-A", UA, "-L",
                                f"https://xiaomistore.com.sv/producto/{slug}/"],
                               capture_output=True, text=True, timeout=60)
            t = re.search(r'<h1>([^<]+)</h1>', r.stdout)
            pr = re.search(r'<p class="price">(.*?)</p>', r.stdout, re.S)
            if t and pr:
                amount = re.sub(r'[^\d.]', '', html.unescape(re.sub(r'<[^>]+>', '', pr.group(1))))
                items.append({"name": html.unescape(t.group(1)).strip() + " [XiaomiStore]",
                              "price": float(amount) if amount else None, "stock": "InStock",
                              "url": f"https://xiaomistore.com.sv/producto/{slug}/", "source": "XS"})
                pages_ok += 1
        except Exception:
            pages_fail += 1
    return items, pages_ok, pages_fail


# ---------------------------------------------------------------- main
def main():
    do_notify = "--notify" in sys.argv
    os.makedirs(os.path.dirname(STATE), exist_ok=True)

    lock_fh = open(LOCK, "w")
    try:
        fcntl.flock(lock_fh, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        # otra corrida en curso: no tocar estado ni notificar
        try:
            print("\n".join(json.load(open(STATE)).get("last_run_lines", [])))
        except Exception:
            pass
        return 0

    prev = {}
    if os.path.exists(STATE):
        try:
            prev = json.load(open(STATE))
        except Exception:
            prev = {}

    items, ok, fail = fetch_all()
    best = {}
    for key, thr, label, store, match in TARGETS:
        hits = [i for i in items if i.get("price") and match(i["name"])]
        if hits:
            h = min(hits, key=lambda x: x["price"])
            best[key] = {"price": h["price"], "source": h["source"], "name": h["name"], "url": h.get("url", "")}
    for key, label, match in CONTEXT:
        hits = [i for i in items if i.get("price") and match(i["name"])]
        if hits:
            h = min(hits, key=lambda x: x["price"])
            best[key] = {"price": h["price"], "source": h["source"], "name": h["name"], "url": h.get("url", "")}

    lines, alerts = [], []
    for key, thr, label, store, match in TARGETS:
        if key in best:
            px = best[key]["price"]
            lines.append(f"{key}: ${px:g} ({best[key]['source']}) {'BUY' if px <= thr else 'wait'} thr=${thr}")
            if px <= thr:
                alerts.append((key, label, store, px, thr))
        else:
            lines.append(f"{key}: NO_DATA (umbral ${thr})")
    for key, label, match in CONTEXT:
        if key in best:
            lines.append(f"{key}: ${best[key]['price']:g} ({best[key]['source']})")
    lines.append(f"FETCH: pages_ok={ok} pages_fail={fail} items={len(items)}")

    notified = prev.get("notified", {})
    state = dict(prev)
    state["last_observation"] = best
    state["last_run_lines"] = lines
    state["alerted"] = dict(prev.get("alerted", {}))
    for key, thr, label, store, match in TARGETS:
        if key in best and best[key]["price"] <= thr:
            state["alerted"][key] = True

    to_notify = []
    for key, label, store, px, thr in alerts:
        if notified.get(key) != px:      # cruce nuevo o bajó aún más
            base = BASE_PRICES.get(key)
            delta = f" (bajó de ${base})" if base and base > px else ""
            to_notify.append((key, f"{label} a ${px:g}{delta}", best[key]["source"], px))

    fetch_broken = fail >= 4
    if do_notify:
        for key, msg, src, px in to_notify:
            notify("Alt — teléfono: hora de comprar", f"{msg}. {src}. Confirma stock por WhatsApp "
                   "antes de moverte (listado no es stock) y pide precio de contado + garantía 12 meses.")
            notified[key] = px
            log(f"NOTIFY {key} ${px:g} ({src})")
        if fetch_broken and not prev.get("last_fetch_broken"):
            notify("Alt — teléfono: lectura incompleta", f"{fail} fuentes no respondieron; los precios "
                   "de esta semana están incompletos. Lo reintento en la próxima corrida.")
            log(f"FETCH_BROKEN fail={fail}")

    state["notified"] = notified
    state["last_fetch_broken"] = fetch_broken
    hist = state.get("history", [])
    hist.append({k: best[k]["price"] for k in best})
    state["history"] = hist[-40:]
    json.dump(state, open(STATE, "w"), indent=1)
    log(" | ".join(f"{k}=${best[k]['price']:g}" for k in best)
        + f" | fetch_ok={ok} fail={fail}" + (" | ALERTA" if alerts else ""))

    print("\n".join(lines))
    if alerts:
        print("")
        print("*** ALERTA DE COMPRA ***")
        for key, label, store, px, thr in alerts:
            print(f" {label}: ${px:g} en {store} — bajo tu techo de ${thr}")
    if fetch_broken:
        print("")
        print(f"*** FALLO DE LECTURA: {fail} fuentes no respondieron (precios incompletos) ***")
    return 0


if __name__ == "__main__":
    sys.exit(main())
