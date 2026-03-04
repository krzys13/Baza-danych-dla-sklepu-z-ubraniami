# Clothing Store Database (MySQL)

Uczelniany projekt relacyjnej bazy danych dla sklepu odzieżowego wykonany w MySQL.  
Baza modeluje pełny proces sprzedaży: produkty, warianty (kolor, rozmiar), egzemplarze, zamówienia, koszyk, płatności oraz zwroty.

## Główne elementy projektu

- Relacyjny model danych dla sklepu e-commerce
- Widoki (VIEW) do analiz sprzedaży i klientów
- Funkcje (FUNCTION) do obliczeń statystycznych i agregacji danych
- Triggery (TRIGGER) zapewniające integralność danych
- Procedury i zapytania analityczne

## Struktura bazy

Najważniejsze encje:

- produkt
- wariant
- egzemplarz
- konto
- klient
- koszyk
- zamowienie
- zamowienie_wariant
- zwrot

## Przykładowe funkcjonalności

- analiza sprzedaży produktów
- identyfikacja najlepszych klientów
- kontrola poprawności danych (np. numer telefonu, ilość produktów)
- automatyczne tworzenie koszyka dla nowych użytkowników
- analiza zwrotów i aktywności klientów

