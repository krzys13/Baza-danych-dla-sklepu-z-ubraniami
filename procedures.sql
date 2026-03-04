DELIMITER ;;
CREATE DEFINER=`admin`@`localhost` PROCEDURE `daj_zamownienie_produkt_wariant`(IN p_zamowienie_id INT)
BEGIN
SELECT za.zamowienie_id, pr.nazwa, pr.plec, wa.kolor, wa.rozmiar, wa.opis, z_a.cena AS cena_produktu, z_a.ilosc  FROM zamowienie za
JOIN zamowienie_wariant z_a USING(zamowienie_id)
JOIN wariant wa USING(wariant_id)
JOIN produkt pr USING(produkt_id)
WHERE za.zamowienie_id = p_zamowienie_id;
END ;;
DELIMITER ;


DELIMITER ;;
CREATE DEFINER=`admin`@`localhost` PROCEDURE `przypisz_produkt_do_kategoria`(IN p_produkt_id INT, IN p_kategoria_nazwa VARCHAR(45) )
BEGIN
    INSERT INTO produkt_kategoria (produkt_id, kategoria_id)  
    VALUES (p_produkt_id, f_daj_kategoria_id(p_kategoria_nazwa) );
END ;;
DELIMITER ;


DELIMITER ;;
CREATE DEFINER=`admin`@`localhost` PROCEDURE `p_daj_zamownienie_produkt_wariant`(IN p_zamowienie_id INT)
BEGIN
SELECT za.zamowienie_id, pr.nazwa, pr.plec, wa.kolor, wa.rozmiar, wa.opis, z_a.cena AS cena_produktu, z_a.ilosc  FROM zamowienie za
JOIN zamowienie_wariant z_a USING(zamowienie_id)
JOIN wariant wa USING(wariant_id)
JOIN produkt pr USING(produkt_id)
WHERE za.zamowienie_id = p_zamowienie_id;
END ;;
DELIMITER ;


DELIMITER ;;
CREATE DEFINER=`admin`@`localhost` PROCEDURE `p_dodaj_do_koszyk`(IN p_koszyk_id INT, IN p_wariant_id INT, IN p_ilosc INT)
BEGIN
    IF EXISTS (SELECT 1 FROM wariant_koszyk WHERE koszyk_id = p_koszyk_id AND wariant_id = p_wariant_id) THEN
        UPDATE wariant_koszyk SET ilosc = ilosc + p_ilosc 
        WHERE koszyk_id = p_koszyk_id AND wariant_id = p_wariant_id;
    ELSE
        INSERT INTO wariant_koszyk (koszyk_id, wariant_id, ilosc) VALUES (p_koszyk_id, p_wariant_id, p_ilosc);
    END IF;
END ;;
DELIMITER ;


DELIMITER ;;
CREATE DEFINER=`admin`@`localhost` PROCEDURE `p_dodaj_produkt`(
	IN p_nazwa_produktu VARCHAR(45),
    IN p_material VARCHAR(45),      
    IN p_plec VARCHAR(45),          
    
    IN p_kategoria_nazwa VARCHAR(45),
    
    IN p_dostawca_nazwa VARCHAR(45) 
)
BEGIN
DECLARE v_produkt_id INT;
DECLARE v_wariant_id INT;
DECLARE v_kategoria_id INT;
DECLARE v_magazyn_id INT;
 START TRANSACTION;


    INSERT INTO produkt (nazwa, material, plec)
    VALUES (p_nazwa_produktu, p_material, p_plec);

    SET v_produkt_id = LAST_INSERT_ID();

    
	call przypisz_produkt_do_kategoria(v_produkt_id, p_kategoria_nazwa);

	INSERT INTO dostawca_produktow (nazwa_firmy, produkt_id)
    VALUES (p_dostawca_nazwa, v_produkt_id);
    COMMIT;
END ;;
DELIMITER ;


DELIMITER ;;
CREATE DEFINER=`admin`@`localhost` PROCEDURE `p_promocja_na_kategoria`(
    IN p_kategoria_nazwa VARCHAR(45),
    IN p_procent DECIMAL(5,2)
)
BEGIN
    DECLARE v_kategoria_id INT;

    SET v_kategoria_id = f_daj_kategoria_id(p_kategoria_nazwa);

    UPDATE wariant wa
    JOIN produkt pr ON wa.produkt_id = pr.produkt_id
    JOIN produkt_kategoria pk ON pk.produkt_id = pr.produkt_id
    SET wa.cena = wa.cena * (1 - (p_procent / 100))
    WHERE pk.kategoria_id = v_kategoria_id;
END ;;
DELIMITER ;


ELIMITER ;;
CREATE DEFINER=`admin`@`localhost` PROCEDURE `p_przypisz_produkt_do_kategoria`(IN p_produkt_id INT, IN p_kategoria_nazwa VARCHAR(45) )
BEGIN
    INSERT INTO produkt_kategoria (produkt_id, kategoria_id)  
    VALUES (p_produkt_id, f_daj_kategoria_id(p_kategoria_nazwa) );
END ;;
DELIMITER ;


DELIMITER ;;
CREATE DEFINER=`admin`@`localhost` PROCEDURE `p_statystyki_klienta`(IN p_konto_id INT)
BEGIN
    SELECT k.konto_id, k.imie, k.nazwisko, f_liczba_zamowien_konta(p_konto_id)  AS liczba_zamowien, f_ilosc_kupionych_sztuk_konto(p_konto_id) AS liczba_kupionych_sztuk, f_suma_wydatkow_konta(p_konto_id)AS laczna_suma
    FROM klient k
    WHERE k.konto_id = p_konto_id
    GROUP BY k.klient_id, k.imie, k.nazwisko;
END ;;
DELIMITER ;


DELIMITER ;;
CREATE DEFINER=`admin`@`localhost` PROCEDURE `p_szukaj_konto_po_imie_nazwisko`(IN p_klient_imie VARCHAR(45), IN p_klient_nazwisko VARCHAR(45) )
BEGIN
SELECT * FROM klient kl
WHERE kl.imie = p_klient_imie
	AND kl.nazwisko = p_klient_nazwisko;
END ;;
DELIMITER ;


DELIMITER ;;
CREATE DEFINER=`admin`@`localhost` PROCEDURE `p_znajdz_zamowienie`(
    IN p_zamowienie_id INT
)
BEGIN
    SELECT *, f_wartosc_zamowienia(p_zamowienie_id) AS wartosc
    FROM zamowienie za
    WHERE za.zamowienie_id = p_zamowienie_id;
END ;;
DELIMITER ;


DELIMITER ;;
CREATE DEFINER=`admin`@`localhost` PROCEDURE `statystyki_klienta`(IN p_konto_id INT)
BEGIN
    SELECT k.imie, k.nazwisko, f_liczba_zamowien_konta(p_konto_id)  AS liczba_zamowien, f_ilosc_kupionych_sztuk_konto(p_konto_id) AS liczba_kupionych_sztuk, f_suma_wydatkow_konta(p_konto_id)AS laczna_suma
    FROM klient k
    WHERE k.konto_id = p_konto_id
    GROUP BY k.klient_id, k.imie, k.nazwisko;
END ;;
DELIMITER ;


DELIMITER ;;
CREATE DEFINER=`admin`@`localhost` PROCEDURE `szukaj_konto_po_imie_nazwisko`(IN p_klient_imie VARCHAR(45), IN p_klient_nazwisko VARCHAR(45) )
BEGIN
SELECT * FROM klient kl
WHERE kl.imie = p_klient_imie
	AND kl.nazwisko = p_klient_nazwisko;
END ;;
DELIMITER ;


DELIMITER ;;
CREATE DEFINER=`admin`@`localhost` PROCEDURE `znajdz_zamowienie`(
    IN p_zamowienie_id INT
)
BEGIN
    SELECT *, f_wartosc_zamowienia(p_zamowienie_id) AS wartosc
    FROM zamowienie za
    WHERE za.zamowienie_id = p_zamowienie_id;
END ;;
DELIMITER ;
