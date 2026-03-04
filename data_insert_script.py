import random
from datetime import datetime, date, timedelta

import mysql.connector
from faker import Faker

fake = Faker("pl_PL")
fake.unique.clear()

DB_CFG = dict(
    host="localhost",
    user="root",
    password="root",
    database="sklep",
    charset="utf8mb4",
)

# =============================
# USTAWIENIA
# =============================
RESET_DB = True  # True = TRUNCATE wszystkich tabel sklep przed seedem

N_MIEJSC = 40
N_ADRESY = 120
N_KONTA = 200

# Produkty: teraz wstawiamy Twoją listę (30 szt.)
N_MAG = 1
EGZ_PER_WARIANT = (3, 12)

N_ZAM = 200
RETURN_RATE = 0.30
REALIZED_RATIO = 0.75  # 70% zamówień zrealizowanych

MAX_PLATNOSC = 999.99  # DECIMAL(5,2) => max 999.99


# =============================
# HELPERY CZASU (DATE vs DATETIME)
# =============================
def ensure_datetime(dt):
    """Konwertuje datetime.date -> datetime.datetime (00:00:00). Zostawia datetime bez zmian."""
    if isinstance(dt, date) and not isinstance(dt, datetime):
        return datetime.combine(dt, datetime.min.time())
    return dt


def dt_between(a, b) -> datetime:
    """Losowa data w zakresie [a, b] (włącznie). Obsługuje date/datetime."""
    a = ensure_datetime(a)
    b = ensure_datetime(b)
    if a > b:
        a, b = b, a
    total_seconds = int((b - a).total_seconds())
    if total_seconds <= 0:
        return a
    return a + timedelta(seconds=random.randint(0, total_seconds))


def dt_after(base_dt, days_min=0, days_max=14) -> datetime:
    """Losowa data po base_dt (włącznie) w zakresie dni. Obsługuje date/datetime."""
    base_dt = ensure_datetime(base_dt)
    delta_days = random.randint(days_min, days_max)
    delta_secs = random.randint(0, 24 * 3600 - 1)
    return base_dt + timedelta(days=delta_days, seconds=delta_secs)


def clamp_order_to_decimal_5_2(items, price_map, max_total=MAX_PLATNOSC):
    """
    items: list[(wariant_id, ilosc)]
    Zmniejsza ilości / usuwa pozycje tak, aby suma nie przekroczyła max_total.
    Zwraca: list[(wariant_id, ilosc)] (bez zer)
    """

    def total():
        return round(sum(price_map[wid] * qty for wid, qty in items), 2)

    items = [(wid, max(1, int(qty))) for wid, qty in items]

    while items and total() > max_total:
        items_sorted = sorted(items, key=lambda x: price_map[x[0]], reverse=True)
        wid, qty = items_sorted[0]
        if qty > 1:
            items = [(w, q - 1 if w == wid else q) for w, q in items]
            items = [(w, q) for w, q in items if q > 0]
        else:
            items = [(w, q) for w, q in items if w != wid]

    return items


def truncate_all(cur):
    """Czyści tabele sklep w kolejności bezpiecznej dla FK (wg Twojego DDL)."""
    cur.execute("SET FOREIGN_KEY_CHECKS=0")

    tables = [
        "zamowienie_egzemplarz",
        "zamowienie_wariant",
        "wariant_koszyk",
        "platnosci",
        "wysylka",
        "zwrot",
        "egzemplarz",
        "zamowienie",
        "koszyk",
        "wariant",
        "dostawca_produktow",
        "produkt_kategoria",
        "produkt",
        "kategoria",
        "firma_kurierska",
        "magazyn",
        "klient",
        "konto",
        "adres",
        "miejscowosc",
    ]

    for t in tables:
        cur.execute(f"TRUNCATE TABLE `{t}`")

    cur.execute("SET FOREIGN_KEY_CHECKS=1")


def main():
    conn = mysql.connector.connect(**DB_CFG)
    conn.autocommit = False
    cur = conn.cursor()

    try:
        if RESET_DB:
            truncate_all(cur)

        # =============================
        # 1) MIEJSCOWOSC
        # =============================
        cur.executemany(
            "INSERT INTO miejscowosc (nazwa) VALUES (%s)",
            [(fake.city(),) for _ in range(N_MIEJSC)],
        )
        cur.execute("SELECT miejscowosc_id FROM miejscowosc")
        miejsc_ids = [r[0] for r in cur.fetchall()]

        # =============================
        # 2) ADRES
        # =============================
        woj = [
            "mazowieckie",
            "małopolskie",
            "śląskie",
            "dolnośląskie",
            "wielkopolskie",
            "pomorskie",
            "łódzkie",
            "lubelskie",
            "podkarpackie",
            "zachodniopomorskie",
        ]

        adresy = [
            (
                random.choice(woj)[:45],
                fake.street_name()[:45],
                fake.postcode()[:45],
                str(random.randint(1, 200))[:45],
                random.choice(miejsc_ids),
            )
            for _ in range(N_ADRESY)
        ]
        cur.executemany(
            """INSERT INTO adres
               (wojewodztwo, adres_ulicy, kod_pocztowy, numer_mieszkania, miejscowosc_id)
               VALUES (%s,%s,%s,%s,%s)""",
            adresy,
        )
        cur.execute("SELECT adres_id FROM adres")
        adres_ids = [r[0] for r in cur.fetchall()]

        # =============================
        # 3) KONTO
        # 1) data_utworzenia <= ostatnie_logowanie
        # =============================
        konta_rows = []
        for _ in range(N_KONTA):
            created = fake.date_time_this_year()
            last_login = dt_after(created, 0, 180)
            konta_rows.append(
                (
                    fake.unique.user_name()[:45],
                    fake.password(length=12)[:45],
                    created,
                    last_login,
                    random.choice(adres_ids),
                )
            )

        cur.executemany(
            """INSERT INTO konto
               (login, haslo, data_utworzenia, ostatnie_logowanie, adres_id)
               VALUES (%s,%s,%s,%s,%s)""",
            konta_rows,
        )

        cur.execute("SELECT konto_id, data_utworzenia, ostatnie_logowanie FROM konto")
        konto_ids = []
        konto_time = {}
        for kid, created, last_login in cur.fetchall():
            konto_ids.append(kid)
            konto_time[kid] = (ensure_datetime(created), ensure_datetime(last_login))

        # =============================
        # 4) KLIENT
        # =============================
        used_phones = set()
        klienci = []
        for konto_id in konto_ids:
            while True:
                phone = random.randint(500_000_000, 899_999_999)
                if phone not in used_phones:
                    used_phones.add(phone)
                    break
            klienci.append(
                (
                    int(konto_id),
                    int(konto_id),
                    fake.first_name()[:45],
                    fake.last_name()[:45],
                    fake.unique.email()[:45],
                    int(phone),
                )
            )

        cur.executemany(
            """INSERT INTO klient
               (klient_id, konto_id, imie, nazwisko, email, numer_telefonu)
               VALUES (%s,%s,%s,%s,%s,%s)""",
            klienci,
        )

        # =============================
        # 5) KOSZYK (1 na konto)
        # =============================
        cur.executemany(
            "INSERT INTO koszyk (konto_id) VALUES (%s)",
            [(k,) for k in konto_ids],
        )
        cur.execute("SELECT koszyk_id FROM koszyk")
        koszyk_ids = [r[0] for r in cur.fetchall()]

        # =============================
        # 6) FIRMA KURIERSKA (ENUM)
        # =============================
        firmy = ["InPost", "DPD", "DHL", "GLS", "FedEx", "Pocztex"]
        cur.executemany(
            "INSERT INTO firma_kurierska (nazwa) VALUES (%s)",
            [(f,) for f in firmy],
        )
        cur.execute("SELECT firma_kurierska_id FROM firma_kurierska")
        firma_ids = [r[0] for r in cur.fetchall()]

        # =============================
        # 7) KATEGORIE (upewnij się, że istnieją)
        # =============================
        wanted_categories = [
            "kurtki",
            "bluzy",
            "t-shirty",
            "spodnie",
            "sukienki",
            "koszule",
            "swetry",
            "obuwie",
            "akcesoria",
            "spódnice",
        ]

        # insert-ignore (bezpieczne przy UNIQUE? brak UNIQUE w DDL, więc sprawdzamy)
        cur.execute("SELECT nazwa, kategoria_id FROM kategoria")
        existing = {name: kid for (name, kid) in cur.fetchall()}

        to_insert = [(c,) for c in wanted_categories if c not in existing]
        if to_insert:
            cur.executemany("INSERT INTO kategoria (nazwa) VALUES (%s)", to_insert)

        cur.execute("SELECT nazwa, kategoria_id FROM kategoria")
        cat_map = {name: int(kid) for (name, kid) in cur.fetchall()}

        # =============================
        # 8) PRODUKTY (Twoja lista 30) + powiązanie z kategorią
        # =============================
        # Mapowanie 'damskie' -> 'zeńskie' (DDL)
        

        products_spec = [
            ("Koszulka z krótkim rękawem BASIC", "bawełna", "męskie", "t-shirty"),
            ("Koszulka oversize z nadrukiem", "bawełna", "damskie", "t-shirty"),
            ("Bluza z kapturem CLASSIC", "poliester", "męskie", "bluzy"),
            ("Bluza bez kaptura SOFT", "bawełna", "damskie", "bluzy"),
            ("Jeansy slim fit", "jeans", "męskie", "spodnie"),
            ("Spodnie materiałowe z wysokim stanem", "wiskoza", "damskie", "spodnie"),
            ("Sukienka letnia MIDI", "len", "damskie", "sukienki"),
            ("Sukienka wieczorowa ELEGANT", "poliester", "damskie", "sukienki"),
            ("Koszula lniana z długim rękawem", "len", "męskie", "koszule"),
            ("Koszula oversize BASIC", "bawełna", "damskie", "koszule"),
            ("Sweter z dekoltem V", "wełna", "męskie", "swetry"),
            ("Sweter cienki z golfem", "wiskoza", "damskie", "swetry"),
            ("Kurtka przejściowa ZIP", "nylon", "męskie", "kurtki"),
            ("Kurtka pikowana LIGHT", "poliester", "damskie", "kurtki"),
            ("Spódnica plisowana MIDI", "poliester", "damskie", "spódnice"),
            ("Spódnica jeansowa MINI", "jeans", "damskie", "spódnice"),
            ("Buty sportowe CLASSIC", "skóra", "męskie", "obuwie"),
            ("Botki na obcasie", "skóra", "damskie", "obuwie"),
            ("Pasek skórzany BASIC", "skóra", "męskie", "akcesoria"),
            ("Torebka listonoszka", "skóra", "damskie", "akcesoria"),
            ("T-shirt sportowy ACTIVE", "poliester", "męskie", "t-shirty"),
            ("T-shirt dopasowany COTTON", "bawełna", "damskie", "t-shirty"),
            ("Spodnie dresowe COMFORT", "bawełna", "męskie", "spodnie"),
            ("Legginsy sportowe FLEX", "nylon", "damskie", "spodnie"),
            ("Kurtka skórzana BIKER", "skóra", "męskie", "kurtki"),
            ("Kardigan długi SOFT", "wełna", "damskie", "swetry"),
            ("Koszula jeansowa CASUAL", "jeans", "męskie", "koszule"),
            ("Sukienka koszulowa DAILY", "bawełna", "damskie", "sukienki"),
            ("Czapka zimowa KNIT", "wełna", "męskie", "akcesoria"),
            ("Szalik oversize WARM", "wiskoza", "damskie", "akcesoria"),
        ]

        # Insert produktów (zachowujemy kolejność z listy)
        prod_rows = [(n[:45], m, p) for (n, m, p, _cat) in products_spec]
        cur.executemany(
            "INSERT INTO produkt (nazwa, material, plec) VALUES (%s,%s,%s)",
            prod_rows,
        )

        # Pobierz IDs produktów po nazwie (wstawiliśmy unikalne nazwy)
        cur.execute("SELECT produkt_id, nazwa FROM produkt")
        prod_by_name = {name: int(pid) for (pid, name) in cur.fetchall()}

        # Powiązania produkt_kategoria 1:1 (dokładnie wg listy)
        pk_rows = []
        for (n, _m, _p, cat_name) in products_spec:
            pid = prod_by_name[n[:45]]
            kid = cat_map[cat_name]
            pk_rows.append((pid, kid))

        cur.executemany(
            "INSERT INTO produkt_kategoria (produkt_id, kategoria_id) VALUES (%s,%s)",
            pk_rows,
        )

        # =============================
        # 9) DOSTAWCA_PRODUKTOW (ENUM) - 1-2 dostawców na produkt
        # =============================
        dostawcy_names = [
            "LPP Logistics",
            "Textil-Pol",
            "ModaSupply",
            "FashionHub",
            "CottonPro",
            "EU Garments",
        ]

        prod_ids = list(prod_by_name.values())
        dp_rows = []
        for pid in prod_ids:
            for _ in range(random.randint(1, 2)):
                dp_rows.append((random.choice(dostawcy_names), pid))

        cur.executemany(
            """INSERT INTO dostawca_produktow (nazwa_firmy, produkt_id)
               VALUES (%s,%s)""",
            dp_rows,
        )

        # =============================
        # 10) WARIANT (bez kolumny `nazwa`)
        # =============================
        kolory = ["czarny", "biały", "beżowy", "granatowy", "zielony", "czerwony", "szary", "brązowy"]
        rozmiary = ["XXS", "XS", "S", "M", "L", "XL", "XXL"]

        warianty = []
        for pid in prod_ids:
            for _ in range(random.randint(2, 5)):
                warianty.append(
                    (
                        random.choice(kolory)[:45],
                        round(random.uniform(19.99, 149.99), 2),
                        fake.sentence(nb_words=12)[:500],
                        random.choice(rozmiary),
                        pid,
                    )
                )

        cur.executemany(
            """INSERT INTO wariant (kolor, cena, opis, rozmiar, produkt_id)
               VALUES (%s,%s,%s,%s,%s)""",
            warianty,
        )

        cur.execute("SELECT wariant_id, cena FROM wariant")
        wariant_price = {int(wid): float(c) for wid, c in cur.fetchall()}
        wariant_ids = list(wariant_price.keys())

        # =============================
        # 11) WARIANT_KOSZYK
        # =============================
        wk_rows = set()
        for koszyk_id in koszyk_ids:
            for wid in random.sample(wariant_ids, k=random.randint(0, 5)):
                wk_rows.add((koszyk_id, wid, random.randint(1, 3)))

        cur.executemany(
            """INSERT INTO wariant_koszyk (koszyk_id, wariant_id, ilosc)
               VALUES (%s,%s,%s)""",
            list(wk_rows),
        )

        # =============================
        # 12) MAGAZYN
        # =============================
        cur.executemany("INSERT INTO magazyn () VALUES ()", [() for _ in range(N_MAG)])
        cur.execute("SELECT magazyn_id FROM magazyn")
        magazyn_ids = [r[0] for r in cur.fetchall()]

        # =============================
        # 13) EGZEMPLARZ + STOCK
        # =============================
        egz = []
        for wid in wariant_ids:
            for _ in range(random.randint(*EGZ_PER_WARIANT)):
                przyjecie = fake.date_time_this_year()
                egz.append(("na_stanie", przyjecie, wid, random.choice(magazyn_ids)))

        cur.executemany(
            """INSERT INTO egzemplarz (status, data_przyjecia, wariant_id, magazyn_id)
               VALUES (%s,%s,%s,%s)""",
            egz,
        )

        cur.execute("SELECT egzemplarz_id, wariant_id, data_przyjecia FROM egzemplarz WHERE status='na_stanie'")
        stock = {}
        for eid, wid, dprz in cur.fetchall():
            stock.setdefault(int(wid), []).append((ensure_datetime(dprz), int(eid)))
        for wid in stock:
            stock[wid].sort(key=lambda x: x[0])

        def available_before(wid: int, cutoff_dt: datetime) -> int:
            return sum(1 for dprz, _ in stock.get(wid, []) if dprz <= cutoff_dt)

        def pop_before(wid: int, cutoff_dt: datetime):
            lst = stock.get(wid, [])
            for i in range(len(lst) - 1, -1, -1):
                if lst[i][0] < cutoff_dt:
                    return lst.pop(i)
            return None

        # =============================
        # 14) ZAMOWIENIA + WYSYLKA + PLATNOSCI + ZWROTY
        # =============================
        typy_plat = [
            "karta",
            "blik",
            "przelew_online",
            "przelew_tradycyjny",
            "paypal",
            "apple_pay",
            "google_pay",
            "za_pobraniem",
        ]
        rodzaje_przes = ["standard", "ekspres", "punkt"]

        powody_zwrotu = [
            "niepasujacy_rozmiar",
            "inny_kolor_niz_oczekiwany",
            "wada_produktu",
            "uszkodzenie_w_transporcie",
            "produkt_niezgodny_z_opisem",
            "nie_spelnia_oczekiwan",
            "pomylone_zamowienie",
            "inna_przyczyna",
        ]
        statusy_zwrotu = ["zgloszony", "w_drodze", "odebrany", "zaakceptowany", "odrzucony", "zrefundowany"]

        REALIZED_COUNT = int(N_ZAM * REALIZED_RATIO)

        for i in range(N_ZAM):
            konto_id = random.choice(konto_ids)
            adres_id = random.choice(adres_ids)
            acc_created, acc_last = konto_time[konto_id]

            # 2) data_zlozenia w [created, last_login]
            data_zlozenia = dt_between(acc_created, acc_last)

            # 70% zrealizowanych
            if i < REALIZED_COUNT:
                status = "zrealizowane"
            else:
                status = random.choice(["nowe", "opłacone", "w_realizacji", "wysłane", "anulowane"])

            # data_zrealizowania tylko gdy status == zrealizowane
            data_zrealizowania = None
            if status == "zrealizowane":
                lo = data_zlozenia + timedelta(hours=6)
                hi = acc_last
                if lo > hi:
                    lo = data_zlozenia
                data_zrealizowania = dt_between(lo, hi)

            cur.execute(
                """INSERT INTO zamowienie (data_zlozenia, status, data_zrealizowania, konto_id, adres_id)
                   VALUES (%s,%s,%s,%s,%s)""",
                (data_zlozenia, status, data_zrealizowania, konto_id, adres_id),
            )
            zam_id = cur.lastrowid

            if status == "anulowane":
                cur.execute(
                    """INSERT INTO platnosci (kwota, typ_platnosci, data_zaplaty, zamowienie_id)
                       VALUES (%s,%s,%s,%s)""",
                    (0.00, random.choice(typy_plat), None, zam_id),
                )
                continue

            # data_wyslania do reguły egzemplarzy
            data_wyslania = None
            if status == "zrealizowane":
                lo = data_zlozenia + timedelta(hours=1)
                hi = data_zrealizowania - timedelta(hours=1)
                if lo > hi:
                    lo = data_zlozenia
                    hi = data_zrealizowania
                data_wyslania = dt_between(lo, hi)
            elif status == "wysłane":
                lo = data_zlozenia + timedelta(hours=1)
                hi = acc_last
                if lo > hi:
                    lo = data_zlozenia
                data_wyslania = dt_between(lo, hi)

            cutoff_for_stock = (data_wyslania - timedelta(minutes=1)) if data_wyslania else data_zlozenia

            picked = random.sample(wariant_ids, k=random.randint(1, 4))
            temp_items = []
            for wid in picked:
                avail = available_before(wid, cutoff_for_stock)
                if avail <= 0:
                    continue
                qty = random.randint(1, min(3, avail))
                temp_items.append((wid, qty))

            items = clamp_order_to_decimal_5_2(temp_items, wariant_price, MAX_PLATNOSC)

            egz_map = []
            qty_by_wid = {}

            for wid, req_qty in items:
                issued = 0
                for _i in range(req_qty):
                    popped = pop_before(wid, cutoff_for_stock)
                    if popped is None:
                        break
                    _dprz, eid = popped
                    egz_map.append((zam_id, eid))
                    issued += 1
                    cur.execute("UPDATE egzemplarz SET status='wydany' WHERE egzemplarz_id=%s", (eid,))
                if issued > 0:
                    qty_by_wid[wid] = qty_by_wid.get(wid, 0) + issued

            if not egz_map:
                cur.execute(
                    "UPDATE zamowienie SET status='anulowane', data_zrealizowania=NULL WHERE zamowienie_id=%s",
                    (zam_id,),
                )
                cur.execute(
                    """INSERT INTO platnosci (kwota, typ_platnosci, data_zaplaty, zamowienie_id)
                       VALUES (%s,%s,%s,%s)""",
                    (0.00, random.choice(typy_plat), None, zam_id),
                )
                continue

            # zamowienie_egzemplarz
            cur.executemany(
                """INSERT INTO zamowienie_egzemplarz (zamowienie_id, egzemplarz_id, zwrot_id)
                   VALUES (%s,%s,%s)""",
                [(z, e, None) for (z, e) in egz_map],
            )

            # zamowienie_wariant
            pozycje = [(zam_id, wid, qty, float(wariant_price[wid])) for wid, qty in qty_by_wid.items()]
            cur.executemany(
                """INSERT INTO zamowienie_wariant (zamowienie_id, wariant_id, ilosc, cena)
                   VALUES (%s,%s,%s,%s)""",
                pozycje,
            )

            # wysylka
            if data_wyslania is not None:
                cur.execute(
                    """INSERT INTO wysylka (zamowienie_id, firma_kurierska_id, data_wyslania, rodzaj_przesylki)
                       VALUES (%s,%s,%s,%s)""",
                    (zam_id, random.choice(firma_ids), data_wyslania, random.choice(rodzaje_przes)),
                )

            # platnosci
            total = round(sum(qty * cena for _, _, qty, cena in pozycje), 2)
            total = min(total, MAX_PLATNOSC)

            if status in ["opłacone", "w_realizacji", "wysłane", "zrealizowane"]:
                if status == "zrealizowane" and data_zrealizowania is not None:
                    hi = data_zrealizowania - timedelta(minutes=5)
                    lo = data_zlozenia
                    if lo > hi:
                        hi = data_zrealizowania
                    data_zaplaty = dt_between(lo, hi)
                else:
                    data_zaplaty = dt_between(data_zlozenia, acc_last)
            else:
                data_zaplaty = None

            cur.execute(
                """INSERT INTO platnosci (kwota, typ_platnosci, data_zaplaty, zamowienie_id)
                   VALUES (%s,%s,%s,%s)""",
                (float(total), random.choice(typy_plat), data_zaplaty, zam_id),
            )

            # zwrot: tylko dla zrealizowanych
            if status == "zrealizowane" and data_zrealizowania is not None and random.random() < RETURN_RATE:
                data_utworzenia = dt_after(data_zrealizowania, 0, 14)

                # data_odebrania > data_zrealizowania
                lo_odb = data_zrealizowania + timedelta(hours=1)
                hi_odb = dt_after(data_utworzenia, 0, 10)
                if lo_odb > hi_odb:
                    hi_odb = dt_after(lo_odb, 0, 2)
                data_odebrania = dt_between(lo_odb, hi_odb)

                status_zw = random.choice(statusy_zwrotu)

                # data_zakonczenia dla: zrefundowany ORAZ odrzucony
                if status_zw in ["zrefundowany", "odrzucony"]:
                    lo_end = data_odebrania + timedelta(hours=1)
                    hi_end = dt_after(data_odebrania, 0, 14)
                    if lo_end > hi_end:
                        hi_end = dt_after(lo_end, 0, 2)
                    data_zakonczenia = dt_between(lo_end, hi_end)
                else:
                    data_zakonczenia = None

                cur.execute(
                    """INSERT INTO zwrot
                       (data_utworzenia, powod_zwrotu, status_zwrotu, data_odebrania_produktow, data_zakonczenia)
                       VALUES (%s,%s,%s,%s,%s)""",
                    (
                        data_utworzenia,
                        random.choice(powody_zwrotu),
                        status_zw,
                        data_odebrania,
                        data_zakonczenia,
                    ),
                )
                zwrot_id = cur.lastrowid

                # podepnij zwrot do części egzemplarzy + ustaw zwrocony
                to_return = random.sample(egz_map, k=random.randint(1, len(egz_map)))
                for _, eid in to_return:
                    cur.execute(
                        """UPDATE zamowienie_egzemplarz
                           SET zwrot_id=%s
                           WHERE zamowienie_id=%s AND egzemplarz_id=%s""",
                        (zwrot_id, zam_id, eid),
                    )
                    cur.execute("UPDATE egzemplarz SET status='zwrocony' WHERE egzemplarz_id=%s", (eid,))

        conn.commit()
        print("✅ Seed zakończony: produkty z listy + kategorie, 70% zrealizowanych, zwroty OK.")

    except Exception as e:
        conn.rollback()
        print("❌ Błąd (rollback):", e)
        raise
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
