DELIMITER $$
DROP TRIGGER IF EXISTS `sprawdz_telefon_klienta`$$
CREATE TRIGGER `sprawdz_telefon_klienta` BEFORE INSERT ON `klient` FOR EACH ROW BEGIN
    IF LENGTH(NEW.numer_telefonu) != 9 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Błąd: Numer telefonu musi składać się z dokładnie 9 cyfr!';
    END IF;
END$$


DROP TRIGGER IF EXISTS `male_litery_login`$$
CREATE TRIGGER `male_litery_login` BEFORE INSERT ON `konto` FOR EACH ROW BEGIN 
	SET NEW.login = LOWER(NEW.login);
END$$


DROP TRIGGER IF EXISTS `auto_tworzenie_koszyka`$$
CREATE TRIGGER `auto_tworzenie_koszyka` AFTER INSERT ON `konto` FOR EACH ROW BEGIN
	IF NEW.rola = 'klient' THEN
		INSERT INTO koszyk (konto_id) VALUES (NEW.konto_id);
    END IF;
END$$


DROP TRIGGER IF EXISTS `aktualizuj_aktywnosc_konta`$$
CREATE TRIGGER `aktualizuj_aktywnosc_konta` BEFORE UPDATE ON `konto` FOR EACH ROW BEGIN
	SET NEW.ostatnie_logowanie = CURRENT_TIMESTAMP;
END$$


DROP TRIGGER IF EXISTS `zakaz_daty_z_przyszlosci`$$
CREATE TRIGGER `zakaz_daty_z_przyszlosci` BEFORE INSERT ON `zamowienie` FOR EACH ROW BEGIN
	IF NEW.data_zlozenia > NOW() THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Błąd: data_zlozenia nie może być w przyszłości';
	END IF;
END$$


DROP TRIGGER IF EXISTS `aktualna_data_przy_tworzeniu_zamowienia`$$
CREATE TRIGGER `aktualna_data_przy_tworzeniu_zamowienia` BEFORE INSERT ON `zamowienie` FOR EACH ROW BEGIN
    SET NEW.data_zlozenia = IFNULL(NEW.data_zlozenia, NOW());
END$$


DROP TRIGGER IF EXISTS `weryfikacja_ilosci_sztuk_wariantu`$$
CREATE TRIGGER `weryfikacja_ilosci_sztuk_wariantu` BEFORE INSERT ON `zamowienie_wariant` FOR EACH ROW BEGIN
	IF NEW.ilosc IS  NULL or NEW.ilosc < 1 THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Błąd: ilosc musi być wieksza lub rowna 1';
	END IF;
END$$

DELIMITER ;

