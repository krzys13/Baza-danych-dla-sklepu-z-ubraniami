DROP VIEW IF EXISTS `v_analiza_calej_sprzedazy`;
CREATE VIEW `v_analiza_calej_sprzedazy` AS
SELECT
    pr.produkt_id AS produkt_id,
    pr.nazwa AS nazwa,
    COUNT(*) AS liczba_sprzedanych
FROM produkt pr
JOIN wariant wa USING (produkt_id)
JOIN egzemplarz eg USING (wariant_id)
JOIN zamowienie_egzemplarz z_e USING (egzemplarz_id)
JOIN zamowienie za USING (zamowienie_id)
WHERE za.status = 'zrealizowane'
  AND z_e.zwrot_id IS NULL
GROUP BY
    pr.produkt_id,
    pr.nazwa;


DROP VIEW IF EXISTS `v_kategoria_dostepne_wariant_ilosc`;
CREATE VIEW `v_kategoria_dostepne_wariant_ilosc` AS
SELECT
    ka.kategoria_id AS kategoria_id,
    ka.nazwa AS nazwa,
    COUNT(*) AS ilosc_egzemplarzy
FROM kategoria ka
LEFT JOIN produkt_kategoria p_k USING (kategoria_id)
LEFT JOIN produkt pr USING (produkt_id)
LEFT JOIN wariant wa USING (produkt_id)
LEFT JOIN egzemplarz eg USING (wariant_id)
WHERE eg.status = 'na_stanie'
GROUP BY ka.kategoria_id;


DROP VIEW IF EXISTS `v_klienci_z_conajmniej_1_zamowieniem`;
CREATE VIEW `v_klienci_z_conajmniej_1_zamowieniem` AS
SELECT DISTINCT
    kon.konto_id AS konto_id,
    kon.login AS login,
    kl.imie AS imie,
    kl.nazwisko AS nazwisko,
    kl.email AS email,
    kl.numer_telefonu AS numer_telefonu,
    ad.wojewodztwo AS wojewodztwo,
    ad.adres_ulicy AS adres_ulicy,
    ad.kod_pocztowy AS kod_pocztowy
FROM konto kon
JOIN klient kl USING (konto_id)
JOIN zamowienie za USING (konto_id)
JOIN miejscowosc mi
    ON mi.miejscowosc_id = kl.miejscowosc_id
JOIN adres ad USING (miejscowosc_id)
WHERE za.status <> 'anulowane';


DROP VIEW IF EXISTS `v_klienci_z_wydatkami_powyzej_sredniej`;
CREATE VIEW `v_klienci_z_wydatkami_powyzej_sredniej` AS
SELECT
    kl.klient_id AS klient_id,
    kl.imie AS imie,
    kl.nazwisko AS nazwisko,
    kl.email AS email,
    ROUND(SUM(z_w.cena * z_w.ilosc), 2) AS suma_wydatkow
FROM klient kl
JOIN konto kon USING (konto_id)
JOIN zamowienie za USING (konto_id)
JOIN zamowienie_wariant z_w USING (zamowienie_id)
WHERE za.status <> 'anulowane'
GROUP BY kl.klient_id
HAVING ROUND(SUM(z_w.cena * z_w.ilosc), 2) > f_srednia_wydatkow_wszystkich_kont();


DROP VIEW IF EXISTS `v_kliencie_online_7_dni_i_produkt_w_koszyku`;
CREATE VIEW `v_kliencie_online_7_dni_i_produkt_w_koszyku` AS
SELECT DISTINCT
    kon.konto_id AS konto_id,
    kon.login AS login,
    kl.imie AS imie,
    kl.nazwisko AS nazwisko,
    kl.email AS email,
    kl.numer_telefonu AS numer_telefonu,
    kos.koszyk_id AS koszyk_id,
    kon.ostatnie_logowanie AS ostatnie_logowanie
FROM konto kon
JOIN klient kl USING (konto_id)
JOIN koszyk kos USING (konto_id)
LEFT JOIN wariant_koszyk wk USING (koszyk_id)
WHERE kon.ostatnie_logowanie >= (NOW() - INTERVAL 7 DAY)
ORDER BY kon.ostatnie_logowanie DESC;


DROP VIEW IF EXISTS `v_produkt_wariant_o_cenie_wiekszej_od_sredniej_ceny_calosci`;
CREATE VIEW `v_produkt_wariant_o_cenie_wiekszej_od_sredniej_ceny_calosci` AS
SELECT
    pr.produkt_id AS produkt_id,
    pr.nazwa AS nazwa,
    pr.material AS material,
    pr.plec AS plec,
    wa.wariant_id AS wariant_id,
    wa.kolor AS kolor,
    wa.cena AS cena,
    wa.opis AS opis,
    wa.rozmiar AS rozmiar
FROM produkt pr
JOIN wariant wa USING (produkt_id)
WHERE wa.cena > (
    SELECT AVG(wariant.cena)
    FROM wariant
);


DROP VIEW IF EXISTS `v_produkty_ilosc`;
CREATE VIEW `v_produkty_ilosc` AS
SELECT
    pr.produkt_id AS produkt_id,
    pr.nazwa AS nazwa,
    pr.plec AS plec,
    COUNT(*) AS `ilość_na_stanie`
FROM produkt pr
JOIN wariant wa USING (produkt_id)
JOIN egzemplarz eg USING (wariant_id)
WHERE eg.status = 'na_stanie'
GROUP BY
    pr.produkt_id,
    pr.nazwa,
    pr.plec;


DROP VIEW IF EXISTS `v_top_10_produkt_wariant_tego_miesiaca`;
CREATE VIEW `v_top_10_produkt_wariant_tego_miesiaca` AS
SELECT
    pr.produkt_id AS produkt_id,
    pr.nazwa AS nazwa,
    wa.kolor AS kolor,
    wa.rozmiar AS rozmiar,
    COUNT(*) AS sprzedane_sztuki
FROM produkt pr
JOIN wariant wa USING (produkt_id)
JOIN egzemplarz eg USING (wariant_id)
JOIN zamowienie_egzemplarz z_e USING (egzemplarz_id)
JOIN zamowienie za USING (zamowienie_id)
WHERE za.status = 'zrealizowane'
  AND z_e.zwrot_id IS NULL
  AND za.data_zlozenia >= (
      CURDATE() - INTERVAL (DAYOFMONTH(CURDATE()) - 1) DAY
  )
GROUP BY
    pr.produkt_id,
    pr.nazwa,
    wa.kolor,
    wa.rozmiar
ORDER BY sprzedane_sztuki DESC
LIMIT 10;


DROP VIEW IF EXISTS `v_top_klienci_2m`;
CREATE VIEW `v_top_klienci_2m` AS
SELECT
    kon.konto_id AS konto_id,
    kon.login AS login,
    kl.imie AS imie,
    kl.nazwisko AS nazwisko,
    kl.email AS email,
    kl.numer_telefonu AS numer_telefonu,
    ad.wojewodztwo AS wojewodztwo,
    ad.adres_ulicy AS adres_ulicy,
    ad.kod_pocztowy AS kod_pocztowy,
    f_top_klienci_liczba_kupionych_sztuk(kon.konto_id) AS liczba_kupionych
FROM konto kon
JOIN klient kl USING (konto_id)
JOIN miejscowosc mi
    ON mi.miejscowosc_id = kl.miejscowosc_id
JOIN adres ad USING (miejscowosc_id)
JOIN zamowienie za USING (konto_id)
WHERE za.status <> 'anulowane'
  AND za.data_zlozenia >= (CURDATE() - INTERVAL 2 MONTH)
GROUP BY kon.konto_id
ORDER BY liczba_kupionych DESC
LIMIT 10;


DROP VIEW IF EXISTS `v_zwroty_do_rozpatrzenia`;
CREATE VIEW `v_zwroty_do_rozpatrzenia` AS
SELECT
    zw.zwrot_id AS zwrot_id,
    zw.status_zwrotu AS status_zwrotu,
    zw.powod_zwrotu AS powod_zwrotu,
    wa.kolor AS kolor,
    wa.rozmiar AS rozmiar,
    pr.nazwa AS nazwa,
    pr.plec AS plec,
    eg.egzemplarz_id AS egzemplarz_id
FROM zwrot zw
JOIN zamowienie_egzemplarz z_e USING (zwrot_id)
JOIN egzemplarz eg USING (egzemplarz_id)
JOIN wariant wa USING (wariant_id)
JOIN produkt pr USING (produkt_id)
JOIN zamowienie za USING (zamowienie_id)
WHERE za.status = 'zrealizowane'
  AND z_e.zwrot_id IS NOT NULL
  AND zw.status_zwrotu IN ('zgloszony', 'w_drodze', 'odebrany')
ORDER BY zw.data_utworzenia DESC;