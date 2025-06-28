# RedSquareHUD: Proces Rysowania i Implementacja UIDaemon

Ten dokument opisuje proces rysowania i implementację UIDaemon w uproszczonej aplikacji `RedSquareHUD` znajdującej się w `final/Simple/`. Przedstawia również potencjalne optymalizacje i obszary do dalszego uproszczenia.

## I. Proces Rysowania

Czerwony kwadrat jest rysowany przy użyciu standardowych komponentów UIKit w ramach `HUDRootViewController`. Oto podział procesu:

1.  **`HUDRootViewController.mm`:** Ten plik zawiera podstawową logikę interfejsu użytkownika HUD.
2.  **Metoda `viewDidLoad`:** Kiedy widok HUD jest ładowany, ta metoda wykonuje:
    *   Tworzy przezroczysty `_contentView` (`UIView`), który służy jako główny kontener dla elementów HUD.
    *   Konfiguruje `UIVisualEffectView` (`_blurView`) z efektem ciemnego rozmycia, aby zapewnić tło dla czerwonego kwadratu. Pomaga to w widoczności na tle różnych treści ekranu.
    *   Tworzy `_redSquareView` (`UIView`), ustawia jego kolor tła na czerwony.
    *   `_redSquareView` jest dodawany jako subview do `contentView` należącego do `_blurView`.
    *   `_blurView` jest dodawany jako subview do `_contentView`.
    *   Na koniec `_contentView` jest dodawany jako subview do głównego widoku kontrolera widoku (`self.view`).
3.  **Metoda `updateViewConstraints`:** Ta metoda definiuje układ za pomocą ograniczeń Auto Layout:
    *   Dodawane są ograniczenia centrujące `_redSquareView` wewnątrz `_blurView`.
    *   Dodawane są ograniczenia, aby `_blurView` otaczał `_redSquareView` ze stałym wypełnieniem (5 punktów pionowo, 10 punktów poziomo).
    *   Dodawane są ograniczenia pozycjonujące `_contentView` (który teraz dopasowuje swój rozmiar na podstawie widoku rozmycia) na górze pośrodku ekranu, lekko odsunięty od górnej kotwicy bezpiecznego obszaru.
4.  **Statyczny Wygląd:** Rozmiar czerwonego kwadratu (20x20 punktów), wypełnienie widoku rozmycia, promień narożnika (4.5 punktu) i górny margines (5 punktów) są zakodowane na stałe jako wartości `CGFloat` w `updateViewConstraints`. Skutkuje to statycznym, niekonfigurowalnym wyglądem.

## II. Implementacja UIDaemon

HUD działa jako oddzielny proces w tle, wykorzystując możliwości UIDaemon, co pozwala mu nakładać się na inne aplikacje. Jest to zorganizowane głównie poprzez `main.mm` i funkcje pomocnicze.

1.  **`main.mm` (Punkt Wejścia):**
    *   Sprawdza argumenty wiersza poleceń (`argc`, `argv`).
    *   **Normalne Uruchomienie Aplikacji (brak argumentów lub nieznane argumenty):** Wywołuje `UIApplicationMain(argc, argv, nil, @"MainApplicationDelegate");`, aby uruchomić standardową aplikację na pierwszym planie (tę z przyciskiem). Zauważ, że używa domyślnej klasy `UIApplication` (`nil`) i `MainApplicationDelegate`.
    *   **Uruchomienie HUD (`-hud` arg):**
        *   Pobiera bieżący identyfikator procesu (PID).
        *   Zapisuje PID do pliku cache (`/var/mobile/Library/Caches/com.user.redsquarehud.pid`) w celu śledzenia.
        *   Inicjalizuje niezbędne usługi systemowe (`GSInitialize`, `BKSDisplayServicesStart`, `UIApplicationInitialize`).
        *   Tworzy instancje niestandardowych `HUDMainApplication` i `HUDMainApplicationDelegate`.
        *   Ustawia delegata w instancji współdzielonej aplikacji.
        *   Wywołuje `[UIApplication.sharedApplication __completeAndRunAsPlugin];`, co jest kluczowym wywołaniem prywatnego API do uruchomienia aplikacji w trybie UIDaemon w tle.
        *   Uruchamia pętlę zdarzeń (`CFRunLoopRun()`), aby utrzymać proces przy życiu.
    *   **Zakończenie HUD (`-exit` arg):** Odczytuje PID z pliku cache, wysyła sygnał `SIGKILL` do tego PID i usuwa plik PID.
    *   **Sprawdzenie HUD (`-check` arg):** Odczytuje plik PID i używa `kill(pid, 0)`, aby sprawdzić, czy proces o tym PID istnieje (zwraca 0, jeśli istnieje, -1 w przeciwnym razie). Kończy działanie z błędem (niezerowym), jeśli proces istnieje, w przeciwnym razie z sukcesem (zero).
2.  **`HUDHelper.mm`:**
    *   `SetHUDEnabled(BOOL isEnabled)`: Ta funkcja jest wywoływana przez `RootViewController` głównej aplikacji po naciśnięciu przycisku.
        *   Wysyła powiadomienie `NOTIFY_DISMISSAL_HUD` (na które nasłuchuje działający proces HUD, aby się zakończyć).
        *   Używa `posix_spawn` do uruchomienia pliku wykonywalnego aplikacji z argumentem `-hud` (jeśli `isEnabled` to `YES`) lub `-exit` (jeśli `isEnabled` to `NO`). Ustawia atrybuty persony do uruchomienia jako root, jeśli nie jest to symulator.
    *   `IsHUDEnabled(void)`: Wywoływana przez `RootViewController` głównej aplikacji w celu określenia początkowego stanu przycisku. Uruchamia plik wykonywalny z argumentem `-check` i zwraca `YES`, jeśli proces sprawdzający zakończy się ze statusem niezerowym (co wskazuje, że proces HUD został znaleziony jako działający).
3.  **`HUDMainApplication.mm`:**
    *   Metoda `init` rejestruje nasłuchiwacz dla powiadomienia Darwin `NOTIFY_DISMISSAL_HUD`. Po otrzymaniu, animuje alfę okna HUD do 0, a następnie wywołuje `terminateWithSuccess`, aby czysto zakończyć proces HUD.
4.  **`HUDMainApplicationDelegate.mm`:**
    *   `application:didFinishLaunchingWithOptions:`: Tworzy `HUDRootViewController` i `HUDMainWindow`, ustawia główny kontroler widoku, ustawia wysoki poziom okna (aby pojawiało się nad innymi aplikacjami), czyni okno widocznym i, co ważne, używa prywatnego API `SBSAccessibilityWindowHostingController` do zarejestrowania okna, co jest często konieczne, aby okna UIDaemon wyświetlały się poprawnie.
5.  **`HUDMainWindow.mm`:**
    *   Nadpisuje prywatne metody, takie jak `_isSystemWindow`, `_isWindowServerHostingManaged`, `_isSecure`, `_shouldCreateContextAsSecure`, aby odpowiednio skonfigurować okno jako nakładkę systemową.
    *   Kluczowe jest, że `_ignoresHitTest` zwraca `YES`, co sprawia, że okno przepuszcza zdarzenia dotykowe do tego, co znajduje się pod nim (ponieważ uproszczony HUD nie jest interaktywny).

## III. Kluczowe Pliki i Lokalizacje (`final/Simple/`)

*   **UI i Rysowanie (Proces HUD):**
    *   `HUDRootViewController.h/.mm`: Tworzy i układa czerwony kwadrat oraz widok rozmycia.
    *   `HUDMainWindow.h/.mm`: Niestandardowa klasa okna dla nakładki HUD.
*   **Konfiguracja i Cykl Życia UIDaemon (Proces HUD):**
    *   `main.mm`: Obsługuje parsowanie argumentów, logikę uruchamiania/kończenia/sprawdzania procesu, inicjalizację UIDaemon.
    *   `HUDMainApplication.h/.mm`: Niestandardowa klasa aplikacji, obsługuje powiadomienie o zakończeniu.
    *   `HUDMainApplicationDelegate.h/.mm`: Konfiguruje okno i kontroler widoku HUD, rejestruje w hostingu dostępności.
*   **Uruchamianie/Sprawdzanie (Główna Aplikacja -> HUD):**
    *   `HUDHelper.h/.mm`: Dostarcza `IsHUDEnabled` i `SetHUDEnabled` używając `posix_spawn`.
*   **Interfejs Głównej Aplikacji (Aplikacja na Pierwszym Planie):**
    *   `RootViewController.h/.mm`: Zawiera przycisk "Otwórz/Zamknij HUD" i wywołuje `HUDHelper`.
    *   `MainButton.h/.mm`: Prosta podklasa `UIButton` dla animacji głównego przycisku.
    *   `MainApplicationDelegate.h/.mm`: Standardowy delegat aplikacji dla aplikacji na pierwszym planie.
*   **System Budowania i Konfiguracja:**
    *   `Makefile`: Plik konfiguracyjny budowania dla Theos.
    *   `entitlements.plist`: Wymagane uprawnienia dla UIDaemon, wykonywania w tle itp.
    *   `Resources/Info.plist`: Standardowy plik Info.plist aplikacji.
    *   `control`: Plik kontrolny Debiana do pakowania.
    *   `headers/`: Zawiera niezbędne nagłówki prywatnych frameworków.

## IV. Potencjalne Optymalizacje i Dalsze Uproszczenia

*   **Uproszczenie Ograniczeń:** Zamiast używać Auto Layout w `HUDRootViewController`, bezpośrednie ustawienie `frame` dla `_contentView`, `_blurView` i `_redSquareView` mogłoby nieznacznie zmniejszyć narzut, chociaż czyni układ mniej elastycznym.
*   **Zmniejszenie Użycia Prywatnego API:** Zastąpienie wywołań prywatnego API (np. `__completeAndRunAsPlugin`, `SBSAccessibilityWindowHostingController`, metod w `UIApplication+Private.h`, `HUDMainWindow`) publicznymi alternatywami uczyniłoby aplikację bardziej stabilną w przyszłych wersjach iOS, ale znalezienie publicznych odpowiedników dla nakładek UIDaemon jest trudne lub niemożliwe.
*   **Obsługa Błędów:** Dodaj bardziej szczegółowe logowanie lub informację zwrotną dla użytkownika, jeśli `posix_spawn` zawiedzie w `HUDHelper.mm`.
*   **Połączenie `HUDHelper`:** Logika z `HUDHelper` mogłaby potencjalnie zostać połączona z `RootViewController` (dla sprawdzania/uruchamiania) i `main.mm` (dla logiki `-exit`), eliminując parę plików.
*   **Domyślna Aplikacja/Delegat dla HUD:** Możliwe, że dałoby się użyć domyślnej klasy `UIApplication` i prostszego delegata dla procesu HUD, jeśli obsługa zakończenia przez `HUDMainApplication` nie jest absolutnie konieczna (zakończenie mogłoby być obsługiwane wyłącznie przez `SIGKILL` za pomocą argumentu `-exit`). Usunęłoby to `HUDMainApplication.h/.mm`.
*   **Usunięcie Rozmycia:** Jeśli tło z rozmyciem nie jest pożądane, usunięcie `_blurView` i dodanie `_redSquareView` bezpośrednio do `_contentView` uprościłoby hierarchię widoków.

Wybór, które uproszczenia zastosować, zależy od kompromisu między zwięzłością kodu a potencjalną przyszłą elastycznością lub solidnością.