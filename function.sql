
DELIMITER $$
DROP FUNCTION IF EXISTS `f_daj_kategoria_id`$$
CREATE FUNCTION `f_daj_kategoria_id`(p_kategoria_nazwa VARCHAR(45)) RETURNS int
    DETERMINISTIC
BEGIN
	DECLARE kategoria_id INT DEFAULT NULL;

    SELECT ka.kategoria_id INTO kategoria_id
	FROM kategoria ka
    WHERE ka.nazwa = p_kategoria_nazwa
    LIMIT 1;
    
    RETURN kategoria_id ;
END $$


DROP FUNCTION IF EXISTS `f_daj_status_zamowienia`$$
CREATE FUNCTION `f_daj_status_zamowienia`(
    p_zamowienie_id INT
) RETURNS varchar(45) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
    DECLARE v_status VARCHAR(45) DEFAULT NULL;

    SELECT z.status
    INTO v_status
    FROM zamowienie z
    WHERE z.zamowienie_id = p_zamowienie_id
    LIMIT 1;

    RETURN v_status;
END $$


DROP FUNCTION IF EXISTS `f_ilosc_dostepnych_sztuk_wariantu`$$
CREATE FUNCTION `f_ilosc_dostepnych_sztuk_wariantu`(p_wariant_id INT) RETURNS int
    DETERMINISTIC
BEGIN
	DECLARE ilosc INT;
	SET ilosc = 0;

    SELECT COUNT(*) INTO ilosc
	FROM wariant w
    JOIN egzemplarz e ON e.wariant_id = p_wariant_id
    WHERE w.wariant_id = e.wariant_id
		AND e.status = 'na_stanie';

    RETURN ilosc ;
END $$


DROP FUNCTION IF EXISTS `f_ilosc_kupionych_sztuk_konto`$$
CREATE FUNCTION `f_ilosc_kupionych_sztuk_konto`( p_konto_id INT) RETURNS int
    DETERMINISTIC
BEGIN

	DECLARE v_liczba_kupionych_sztuk INT DEFAULT 0;

	SELECT COUNT(*) 
	INTO v_liczba_kupionych_sztuk
    FROM konto ko
    LEFT JOIN zamowienie za USING(konto_id)
    LEFT JOIN zamowienie_egzemplarz z_e USING(zamowienie_id)
    WHERE ko.konto_id = p_konto_id
		AND za.status <> 'anulowane'
		AND z_e.zwrot_id IS NULL
	GROUP BY ko.konto_id;
        
	RETURN v_liczba_kupionych_sztuk;
END $$


DROP FUNCTION IF EXISTS `f_liczba_zamowien_konta`$$
CREATE FUNCTION `f_liczba_zamowien_konta`(
    p_konto_id INT
) RETURNS int
    DETERMINISTIC
BEGIN
    DECLARE v_liczba INT;

    SELECT COUNT(*)
    INTO v_liczba
    FROM zamowienie za
    WHERE za.konto_id = p_konto_id;

    RETURN v_liczba;
END $$


DROP FUNCTION IF EXISTS `f_suma_wydatkow_konta`$$
CREATE FUNCTION `f_suma_wydatkow_konta`(
    p_konto_id INT
) RETURNS decimal(10,2)
    DETERMINISTIC
BEGIN
    DECLARE v_suma DECIMAL(10,2);

    SELECT ROUND(SUM(z_w.cena * z_w.ilosc), 2)
    INTO v_suma
    FROM zamowienie za
    JOIN zamowienie_wariant z_w USING(zamowienie_id)
    WHERE za.konto_id = p_konto_id
      AND za.status <> 'anulowane';

    RETURN IFNULL(v_suma, 0.00);
END $$


DROP FUNCTION IF EXISTS `f_srednia_wydatkow_wszystkich_kont`$$
CREATE FUNCTION `f_srednia_wydatkow_wszystkich_kont`() RETURNS decimal(10,2)
    DETERMINISTIC
BEGIN
    DECLARE v_avg DECIMAL(10,2);

    SELECT ROUND(AVG(suma), 2) INTO v_avg
    FROM (
        SELECT IFNULL(SUM(z_w.cena * z_w.ilosc), 0) AS suma
        FROM konto ko
        LEFT JOIN zamowienie za ON za.konto_id = ko.konto_id
        LEFT JOIN zamowienie_wariant z_w ON z_w.zamowienie_id = za.zamowienie_id
        WHERE za.status <> 'anulowane' OR za.status IS NULL
        GROUP BY ko.konto_id
    ) t;

    RETURN IFNULL(v_avg, 0.00);
END $$


DROP FUNCTION IF EXISTS `f_top_klienci_liczba_kupionych_sztuk`$$
CREATE FUNCTION `f_top_klienci_liczba_kupionych_sztuk`(
    p_konto_id INT
) RETURNS int
    DETERMINISTIC
BEGIN
    DECLARE v_liczba_kupionych_sztuk INT DEFAULT 0;

    SELECT COUNT(*)
	INTO v_liczba_kupionych_sztuk
    FROM konto ko
    LEFT JOIN zamowienie za USING(konto_id)
    LEFT JOIN zamowienie_egzemplarz z_e USING(zamowienie_id)
    WHERE ko.konto_id = p_konto_id
		AND za.status <> 'anulowane'
		AND z_e.zwrot_id IS NULL
	GROUP BY ko.konto_id;
        
	RETURN v_liczba_kupionych_sztuk;
END $$


DELIMITER ;
