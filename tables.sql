
DROP TABLE IF EXISTS `adres`;
CREATE TABLE `adres` (
  `adres_id` int NOT NULL AUTO_INCREMENT,
  `wojewodztwo` varchar(45) NOT NULL,
  `adres_ulicy` varchar(45) NOT NULL,
  `kod_pocztowy` varchar(45) NOT NULL,
  `numer_mieszkania` varchar(45) NOT NULL,
  `miejscowosc_id` int NOT NULL,
  PRIMARY KEY (`adres_id`),
  KEY `fk_adres_miejscowosc1_idx` (`miejscowosc_id`),
  CONSTRAINT `fk_adres_miejscowosc1` FOREIGN KEY (`miejscowosc_id`) REFERENCES `miejscowosc` (`miejscowosc_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `dostawca_produktow`;
CREATE TABLE `dostawca_produktow` (
  `dostawca_produktow_id` int NOT NULL AUTO_INCREMENT,
  `nazwa_firmy` enum('LPP Logistics','Textil-Pol','ModaSupply','FashionHub','CottonPro','EU Garments') NOT NULL,
  `produkt_id` int NOT NULL,
  PRIMARY KEY (`dostawca_produktow_id`),
  KEY `fk_dostawcy_produktow_produkt1_idx` (`produkt_id`),
  CONSTRAINT `fk_dostawcy_produktow_produkt1` FOREIGN KEY (`produkt_id`) REFERENCES `produkt` (`produkt_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `egzemplarz`;
CREATE TABLE `egzemplarz` (
  `egzemplarz_id` int NOT NULL AUTO_INCREMENT,
  `status` enum('na_stanie','wydany','zwrocony','uszkodzony') NOT NULL,
  `data_przyjecia` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `wariant_id` int NOT NULL,
  `magazyn_id` int NOT NULL,
  PRIMARY KEY (`egzemplarz_id`),
  KEY `fk_egzemplarz_magazyn1_idx` (`magazyn_id`),
  KEY `fk_egzemplarz_wariant1_idx` (`wariant_id`),
  CONSTRAINT `fk_egzemplarz_magazyn1` FOREIGN KEY (`magazyn_id`) REFERENCES `magazyn` (`magazyn_id`),
  CONSTRAINT `fk_egzemplarz_wariant1` FOREIGN KEY (`wariant_id`) REFERENCES `wariant` (`wariant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `firma_kurierska`;
CREATE TABLE `firma_kurierska` (
  `firma_kurierska_id` int NOT NULL AUTO_INCREMENT,
  `nazwa` varchar(45) NOT NULL,
  PRIMARY KEY (`firma_kurierska_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `kategoria`;
CREATE TABLE `kategoria` (
  `kategoria_id` int NOT NULL AUTO_INCREMENT,
  `nazwa` varchar(45) NOT NULL,
  PRIMARY KEY (`kategoria_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `klient`;
CREATE TABLE `klient` (
  `klient_id` int unsigned NOT NULL,
  `imie` varchar(45) NOT NULL,
  `nazwisko` varchar(45) NOT NULL,
  `email` varchar(45) NOT NULL,
  `numer_telefonu` int NOT NULL,
  `konto_id` int NOT NULL,
  PRIMARY KEY (`klient_id`,`konto_id`),
  UNIQUE KEY `email_UNIQUE` (`email`),
  UNIQUE KEY `numer_telefonu_UNIQUE` (`numer_telefonu`),
  UNIQUE KEY `klient_id_UNIQUE` (`klient_id`),
  KEY `fk_klient_konto1_idx` (`konto_id`),
  CONSTRAINT `fk_klient_konto1` FOREIGN KEY (`konto_id`) REFERENCES `konto` (`konto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `konto`;
CREATE TABLE `konto` (
  `konto_id` int NOT NULL AUTO_INCREMENT,
  `login` varchar(45) NOT NULL,
  `haslo` varchar(45) NOT NULL,
  `data_utworzenia` datetime NOT NULL,
  `ostatnie_logowanie` datetime NOT NULL,
  `adres_id` int NOT NULL,
  PRIMARY KEY (`konto_id`),
  UNIQUE KEY `login_UNIQUE` (`login`),
  UNIQUE KEY `konto_id_UNIQUE` (`konto_id`),
  KEY `fk_konto_adres1_idx` (`adres_id`),
  CONSTRAINT `fk_konto_adres1` FOREIGN KEY (`adres_id`) REFERENCES `adres` (`adres_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `koszyk`;
CREATE TABLE `koszyk` (
  `koszyk_id` int NOT NULL AUTO_INCREMENT,
  `konto_id` int NOT NULL,
  PRIMARY KEY (`koszyk_id`),
  UNIQUE KEY `koszyk_id_UNIQUE` (`koszyk_id`),
  KEY `fk_koszyk_konto1_idx` (`konto_id`),
  CONSTRAINT `fk_koszyk_konto1` FOREIGN KEY (`konto_id`) REFERENCES `konto` (`konto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `magazyn`;
CREATE TABLE `magazyn` (
  `magazyn_id` int NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`magazyn_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `miejscowosc`;
CREATE TABLE `miejscowosc` (
  `miejscowosc_id` int NOT NULL AUTO_INCREMENT,
  `nazwa` varchar(45) NOT NULL,
  PRIMARY KEY (`miejscowosc_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `platnosci`;
CREATE TABLE `platnosci` (
  `platnosc_id` int NOT NULL AUTO_INCREMENT,
  `kwota` decimal(5,2) NOT NULL,
  `typ_platnosci` enum('karta','blik','przelew_online','przelew_tradycyjny','paypal','apple_pay','google_pay','za_pobraniem') NOT NULL,
  `data_zaplaty` datetime DEFAULT NULL,
  `zamowienie_id` int NOT NULL,
  PRIMARY KEY (`platnosc_id`),
  KEY `fk_platnosci_zamowienie1_idx` (`zamowienie_id`),
  CONSTRAINT `fk_platnosci_zamowienie1` FOREIGN KEY (`zamowienie_id`) REFERENCES `zamowienie` (`zamowienie_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `produkt`;
CREATE TABLE `produkt` (
  `produkt_id` int NOT NULL AUTO_INCREMENT,
  `nazwa` varchar(45) NOT NULL,
  `material` enum('bawełna','len','poliester','wełna','wiskoza','skóra','jeans','nylon') NOT NULL,
  `plec` enum('męskie','damskie') NOT NULL,
  `produktcol` varchar(80) DEFAULT NULL,
  PRIMARY KEY (`produkt_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `produkt_kategoria`;
CREATE TABLE `produkt_kategoria` (
  `produkt_id` int NOT NULL,
  `kategoria_id` int NOT NULL,
  PRIMARY KEY (`produkt_id`,`kategoria_id`),
  KEY `fk_produkt_has_kategoria_kategoria1_idx` (`kategoria_id`),
  KEY `fk_produkt_has_kategoria_produkt1_idx` (`produkt_id`),
  CONSTRAINT `fk_produkt_has_kategoria_kategoria1` FOREIGN KEY (`kategoria_id`) REFERENCES `kategoria` (`kategoria_id`),
  CONSTRAINT `fk_produkt_has_kategoria_produkt1` FOREIGN KEY (`produkt_id`) REFERENCES `produkt` (`produkt_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `wariant`;
CREATE TABLE `wariant` (
  `wariant_id` int NOT NULL AUTO_INCREMENT,
  `kolor` varchar(45) NOT NULL,
  `cena` float NOT NULL,
  `opis` varchar(500) NOT NULL,
  `rozmiar` enum('XXS','XS','S','M','L','XL','XXL') NOT NULL,
  `produkt_id` int NOT NULL,
  PRIMARY KEY (`wariant_id`),
  KEY `fk_wariant_produkt1_idx` (`produkt_id`),
  CONSTRAINT `fk_wariant_produkt1` FOREIGN KEY (`produkt_id`) REFERENCES `produkt` (`produkt_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `wariant_koszyk`;
CREATE TABLE `wariant_koszyk` (
  `koszyk_id` int NOT NULL,
  `wariant_id` int NOT NULL,
  `ilosc` int DEFAULT NULL,
  PRIMARY KEY (`koszyk_id`,`wariant_id`),
  KEY `fk_wariant_koszyk_koszyk1_idx` (`koszyk_id`),
  KEY `fk_wariant_koszyk_wariant1_idx` (`wariant_id`),
  CONSTRAINT `fk_wariant_koszyk_koszyk1` FOREIGN KEY (`koszyk_id`) REFERENCES `koszyk` (`koszyk_id`),
  CONSTRAINT `fk_wariant_koszyk_wariant1` FOREIGN KEY (`wariant_id`) REFERENCES `wariant` (`wariant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `wysylka`;
CREATE TABLE `wysylka` (
  `zamowienie_id` int NOT NULL,
  `firma_kurierska_id` int NOT NULL,
  `data_wyslania` datetime DEFAULT NULL,
  `rodzaj_przesylki` varchar(45) NOT NULL,
  PRIMARY KEY (`zamowienie_id`,`firma_kurierska_id`),
  KEY `fk_wysylka_zamowienie1_idx` (`zamowienie_id`),
  KEY `fk_wysylka_firma_kurierskia1_idx` (`firma_kurierska_id`),
  CONSTRAINT `fk_wysylka_firma_kurierskia1` FOREIGN KEY (`firma_kurierska_id`) REFERENCES `firma_kurierska` (`firma_kurierska_id`),
  CONSTRAINT `fk_wysylka_zamowienie1` FOREIGN KEY (`zamowienie_id`) REFERENCES `zamowienie` (`zamowienie_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `zamowienie`;
CREATE TABLE `zamowienie` (
  `zamowienie_id` int NOT NULL AUTO_INCREMENT,
  `data_zlozenia` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` enum('nowe','opłacone','w_realizacji','wysłane','zrealizowane','anulowane') NOT NULL,
  `data_zrealizowania` datetime DEFAULT NULL,
  `konto_id` int NOT NULL,
  `adres_id` int NOT NULL,
  PRIMARY KEY (`zamowienie_id`),
  KEY `fk_zamowienie_konto1_idx` (`konto_id`),
  KEY `fk_zamowienie_adres1_idx` (`adres_id`),
  CONSTRAINT `fk_zamowienie_adres1` FOREIGN KEY (`adres_id`) REFERENCES `adres` (`adres_id`),
  CONSTRAINT `fk_zamowienie_konto1` FOREIGN KEY (`konto_id`) REFERENCES `konto` (`konto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `zamowienie_egzemplarz`;
CREATE TABLE `zamowienie_egzemplarz` (
  `zamowienie_id` int NOT NULL,
  `egzemplarz_id` int NOT NULL,
  `zwrot_id` int DEFAULT NULL,
  PRIMARY KEY (`zamowienie_id`,`egzemplarz_id`),
  KEY `fk_zamownienie_egzemplarz_egzemplarz1_idx` (`egzemplarz_id`),
  KEY `fk_zamownienie_egzemplarz_zwrot1_idx` (`zwrot_id`),
  CONSTRAINT `fk_zamownienie_egzemplarz_egzemplarz1` FOREIGN KEY (`egzemplarz_id`) REFERENCES `egzemplarz` (`egzemplarz_id`),
  CONSTRAINT `fk_zamownienie_egzemplarz_zamowienie1` FOREIGN KEY (`zamowienie_id`) REFERENCES `zamowienie` (`zamowienie_id`),
  CONSTRAINT `fk_zamownienie_egzemplarz_zwrot1` FOREIGN KEY (`zwrot_id`) REFERENCES `zwrot` (`zwrot_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;




DROP TABLE IF EXISTS `zamowienie_wariant`;

CREATE TABLE `zamowienie_wariant` (
  `zamowienie_id` int NOT NULL,
  `wariant_id` int NOT NULL,
  `ilosc` int NOT NULL,
  `cena` float NOT NULL,
  PRIMARY KEY (`zamowienie_id`,`wariant_id`),
  KEY `fk_zamowienie_wariant_zamowienie1_idx` (`zamowienie_id`),
  KEY `fk_zamowienie_wariant_wariant1_idx` (`wariant_id`),
  CONSTRAINT `fk_zamowienie_wariant_wariant1` FOREIGN KEY (`wariant_id`) REFERENCES `wariant` (`wariant_id`),
  CONSTRAINT `fk_zamowienie_wariant_zamowienie1` FOREIGN KEY (`zamowienie_id`) REFERENCES `zamowienie` (`zamowienie_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `zwrot`;
CREATE TABLE `zwrot` (
  `zwrot_id` int NOT NULL AUTO_INCREMENT,
  `data_utworzenia` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `powod_zwrotu` enum('niepasujacy_rozmiar','inny_kolor_niz_oczekiwany','wada_produktu','uszkodzenie_w_transporcie','produkt_niezgodny_z_opisem','nie_spelnia_oczekiwan','pomylone_zamowienie','inna_przyczyna') NOT NULL,
  `status_zwrotu` enum('zgloszony','w_drodze','odebrany','zaakceptowany','odrzucony','zrefundowany') NOT NULL,
  `data_odebrania_produktow` datetime DEFAULT NULL,
  `data_zakonczenia` datetime DEFAULT NULL,
  PRIMARY KEY (`zwrot_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
