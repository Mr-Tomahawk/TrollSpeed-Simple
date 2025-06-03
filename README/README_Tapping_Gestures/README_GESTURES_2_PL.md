# Implementacja Widoczności HUD Kontrolowanej Gestami

Ten dokument opisuje, jak zaimplementowano gest stuknięcia trzema palcami w głównej aplikacji uruchamiającej, aby przełączać widoczność zewnętrznego procesu HUD (Heads-Up Display). Komunikacja między aplikacją uruchamiającą a procesem HUD odbywa się za pomocą powiadomień Darwin.

## Zmiany Wprowadzone w Tym Projekcie (RedSquareHUD)

Aby umożliwić kontrolowaną gestami widoczność dla RedSquareHUD, wprowadzono następujące modyfikacje:

1.  **Współdzielona Stała Powiadomienia:**
    *   Unikalna nazwa powiadomienia Darwin, `kToggleHUDVisibilityNotificationName` (np. `"com.yourcompany.simplehud.toggleVisibility"`), została zdefiniowana jako statyczna stała `NSString`.
    *   Ta stała została umieszczona w pliku `RedSquareHUD-Prefix.pch`, aby była dostępna zarówno dla głównej aplikacji uruchamiającej, jak i dla procesu HUD.

2.  **Główna Aplikacja Uruchamiająca (np. projekt `Simple`):**
    *   **Plik:** `RootViewController.h`
        *   (Początkowo stała była również zadeklarowana tutaj, ale została usunięta, aby uniknąć błędów redefinicji, ponieważ nagłówek prefixowy obsługuje globalne dołączanie.)
    *   **Plik:** `RootViewController.mm`
        *   Zaimportowano `<notify.h>`.
        *   W metodzie `viewDidLoad`:
            *   Utworzono i skonfigurowano `UITapGestureRecognizer` dla gestu stuknięcia trzema palcami, jednym stuknięciem.
            *   Ten rozpoznawacz gestów został dodany do głównego widoku kontrolera root (`self.view`).
            *   Akcja dla tego gestu została ustawiona na nową metodę, `handleHudVisibilityToggleGesture:`.
        *   Zaimplementowano metodę `handleHudVisibilityToggleGesture:(UITapGestureRecognizer *)gesture`:
            *   Gdy gest jest rozpoznawany (stan `UIGestureRecognizerStateEnded`), wysyła powiadomienie Darwin za pomocą `notify_post([kToggleHUDVisibilityNotificationName UTF8String]);`.

3.  **Zewnętrzny Proces HUD (np. proces `RedSquareHUD`):**
    *   **Plik:** `HUDMainApplicationDelegate.mm`
        *   Zaimportowano `<notify.h>`.
        *   Dodano zmienną instancji typu integer (np. `_visibilityToggleToken`) do przechowywania tokenu z rejestracji powiadomienia Darwin.
        *   W metodzie `application:didFinishLaunchingWithOptions:`:
            *   Zarejestrowano nasłuchiwacz dla powiadomienia Darwin `kToggleHUDVisibilityNotificationName` za pomocą `notify_register_dispatch`.
            *   Blok zwrotny dla tego powiadomienia wywołuje nową metodę, `handleVisibilityToggleNotification`.
        *   Zaimplementowano metodę `handleVisibilityToggleNotification`:
            *   Ta metoda przełącza właściwość `hidden` głównego okna HUD (np. `self.window.hidden = !self.window.hidden;`). To sprawia, że HUD pojawia się lub znika bez kończenia jego procesu.
        *   Zaimplementowano metodę `dealloc` do wyrejestrowania nasłuchiwacza powiadomień Darwin za pomocą `notify_cancel(_visibilityToggleToken);`, gdy delegat jest zwalniany.

## Replikowanie Tego dla Twojego Projektu Zewnętrznego Rysowania

Jeśli masz główną aplikację i oddzielny zewnętrzny proces, który obsługuje rysowanie na ekranie (twój HUD), możesz zaimplementować podobny system kontroli gestami w następujący sposób:

**Założenia:**
*   Masz "Aplikację Uruchamiającą" i "Zewnętrzną Aplikację HUD".
*   Czujesz się komfortowo pracując z Objective-C i Theos (lub podobnym systemem budowania).

**Kroki:**

1.  **Zdefiniuj Unikalną Nazwę Powiadomienia:**
    *   Wybierz unikalny ciąg znaków dla swojego powiadomienia Darwin (np. `"com.yourproject.hud.toggleVisibility"`).
    *   Zdefiniuj to jako stałą (np. `static NSString * const kMyHUDToggleNotification = @"...";`).
    *   **Najlepsza Praktyka:** Umieść tę stałą we współdzielonym pliku nagłówkowym lub nagłówku prefixowym (`.pch`), który jest dołączany zarówno przez Twoją Aplikację Uruchamiającą, jak i Zewnętrzną Aplikację HUD. Zapewnia to spójność i pozwala uniknąć literówek.

2.  **Modyfikacje Aplikacji Uruchamiającej:**
    *   **W Twoim Kontrolerze Widoku odpowiedzialnym za wykrywanie gestów (np. `RootViewController.m`):**
        *   Upewnij się, że `<notify.h>` jest zaimportowane.
        *   W `viewDidLoad` (lub podobnej metodzie konfiguracyjnej):
            ```objective-c
            // #import <notify.h> // Na górze pliku
            // extern NSString * const kMyHUDToggleNotification; // Jeśli zdefiniowano w współdzielonym .h lub upewnij się, że .pch go zawiera

            // ... wewnątrz viewDidLoad ...
            UITapGestureRecognizer *toggleGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleToggleGesture:)];
            toggleGesture.numberOfTouchesRequired = 3; // Lub pożądana liczba palców
            toggleGesture.numberOfTapsRequired = 1;    // Lub pożądana liczba stuknięć
            [self.view addGestureRecognizer:toggleGesture];
            // [toggleGesture release]; // Jeśli nie używasz ARC
            ```
        *   Zaimplementuj metodę obsługi gestu:
            ```objective-c
            - (void)handleToggleGesture:(UITapGestureRecognizer *)gesture {
                if (gesture.state == UIGestureRecognizerStateEnded) {
                    NSLog(@"[LauncherApp] Wykryto gest, wysyłanie powiadomienia w celu przełączenia HUD.");
                    notify_post([kMyHUDToggleNotification UTF8String]);
                }
            }
            ```

3.  **Modyfikacje Zewnętrznej Aplikacji HUD:**
    *   **W Delegacie Aplikacji Twojego HUD (np. `HUDAppDelegate.m`):**
        *   Upewnij się, że `<notify.h>` jest zaimportowane.
        *   Dodaj zmienną instancji do przechowywania tokenu powiadomienia:
            ```objective-c
            // @implementation HUDAppDelegate {
            //     int _hudToggleNotificationToken;
            // }
            ```
        *   W `application:didFinishLaunchingWithOptions:` (po skonfigurowaniu okna HUD):
            ```objective-c
            // #import <notify.h> // Na górze pliku
            // extern NSString * const kMyHUDToggleNotification; // Jeśli zdefiniowano w współdzielonym .h lub upewnij się, że .pch go zawiera

            // ... wewnątrz application:didFinishLaunchingWithOptions: ...
            __weak typeof(self) weakSelf = self; // Ważne dla bloku
            notify_register_dispatch(
                [kMyHUDToggleNotification UTF8String],
                &_hudToggleNotificationToken,      // Adres twojej zmiennej tokenu
                dispatch_get_main_queue(),         // Wysyłanie do głównej kolejki dla aktualizacji UI
                ^(int token) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (strongSelf) {
                        [strongSelf handleHUDToggle];
                    }
                }
            );
            ```
        *   Zaimplementuj metodę obsługi powiadomienia:
            ```objective-c
            - (void)handleHUDToggle {
                NSLog(@"[HUDApp] Otrzymano powiadomienie o przełączeniu.");
                // Zakładając, że 'self.hudWindow' to główne UIWindow twojego HUD
                if (self.hudWindow) {
                    self.hudWindow.hidden = !self.hudWindow.hidden;
                    NSLog(@"[HUDApp] Widoczność HUD ustawiona na: %s", self.hudWindow.hidden ? "Ukryty" : "Widoczny");
                }
            }
            ```
        *   Zaimplementuj `dealloc` do czyszczenia nasłuchiwacza powiadomień:
            ```objective-c
            - (void)dealloc {
                if (_hudToggleNotificationToken) {
                    notify_cancel(_hudToggleNotificationToken);
                }
                // [super dealloc]; // Jeśli nie używasz ARC
            }
            ```

**Ważne Uwagi:**

*   **Obsługa Błędów:** Przykładowy kod jest podstawowy. Możesz chcieć dodać bardziej solidne sprawdzanie błędów.
*   **Poziom Okna:** Upewnij się, że poziom okna HUD jest odpowiednio ustawiony, aby w razie potrzeby pojawiał się nad inną zawartością.
*   **Zarządzanie Procesami:** Ten przewodnik obejmuje tylko przełączanie widoczności. Uruchamianie i kończenie procesu HUD to osobne kwestie.
*   **ARC/Ręczne Zarządzanie Pamięcią:** Fragmenty kodu zakładają ARC (Automatyczne Zliczanie Referencji). Jeśli używasz ręcznego zarządzania pamięcią, dostosuj odpowiednio zarządzanie pamięcią (np. `retain`, `release`, `autorelease`).
*   **Alternatywna Komunikacja:** Chociaż powiadomienia Darwin są odpowiednie do prostych przełączeń, do bardziej złożonej wymiany danych między procesami możesz zbadać inne mechanizmy IPC (Komunikacji Międzyprocesowej), takie jak usługi XPC.

Postępując zgodnie z tymi krokami, możesz zaimplementować przełączanie widoczności oparte na gestach dla swojego projektu zewnętrznego rysowania, podobnie jak zrobiono to w tym projekcie.
