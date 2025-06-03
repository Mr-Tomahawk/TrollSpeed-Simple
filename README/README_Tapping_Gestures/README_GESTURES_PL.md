# Analiza Gesty Wielopalcowego Podwójnego Stuknięcia w HuyJIT-ModMenu

Ten dokument szczegółowo opisuje, jak zaimplementowano funkcje podwójnego stuknięcia trzema palcami (aby otworzyć menu) i podwójnego stuknięcia dwoma palcami (aby wyłączyć menu) w analizowanym projekcie oraz dostarcza instrukcji, jak odtworzyć ten mechanizm dla niestandardowego rysowania na ekranie.

## Jak to Działa

Główna logika rozpoznawania gestów znajduje się w pliku `PubgLoad.mm`.

1.  **Inicjalizacja (`+ (void)load` w `PubgLoad.mm`):**
    *   Ta metoda klasy jest automatycznie wywoływana, gdy `PubgLoad` jest ładowany przez środowisko uruchomieniowe Objective-C.
    *   Używa `dispatch_after` do opóźnienia konfiguracji o 3 sekundy, prawdopodobnie aby upewnić się, że główny interfejs użytkownika aplikacji jest zainicjalizowany i gotowy.
    *   Tworzona jest instancja `PubgLoad`.
    *   Metody `initTapGes` (dla gestu trzema palcami) i `initTapGes2` (dla gestu dwoma palcami) są wywoływane w celu skonfigurowania rozpoznawaczy gestów.

2.  **Konfiguracja Rozpoznawacza Gestów:**
    *   **`-(void)initTapGes` (Podwójne Stuknięcie Trzema Palcami - Pokaż Menu):**
        *   Instancjonowany jest `UITapGestureRecognizer`.
        *   `numberOfTapsRequired` jest ustawione na `2`.
        *   `numberOfTouchesRequired` jest ustawione na `3`.
        *   Rozpoznawacz gestów jest dodawany do `[JHPP currentViewController].view`. `JHPP` wydaje się być niestandardową klasą/metodą narzędziową do uzyskiwania odniesienia do aktualnie aktywnego kontrolera widoku.
        *   Celem tego gestu jest sama instancja `PubgLoad`, a selektorem akcji jest `tapIconView`.
    *   **`-(void)initTapGes2` (Podwójne Stuknięcie Dwoma Palcami - Ukryj Menu):**
        *   Instancjonowany jest kolejny `UITapGestureRecognizer`.
        *   `numberOfTapsRequired` jest ustawione na `2`.
        *   `numberOfTouchesRequired` jest ustawione na `2`.
        *   Ten rozpoznawacz jest również dodawany do `[JHPP currentViewController].view`.
        *   Celem jest instancja `PubgLoad`, a selektorem akcji jest `tapIconView2`.

3.  **Obsługa Akcji Gestów:**
    *   **`-(void)tapIconView` (Akcja dla podwójnego stuknięcia trzema palcami):**
        *   Ta metoda jest wywoływana po wykryciu podwójnego stuknięcia trzema palcami.
        *   Zapewnia, że istnieje instancja `ImGuiDrawView` (określana jako `_vna`). `ImGuiDrawView` jest odpowiedzialny za renderowanie menu ImGui.
        *   Wywołuje statyczną metodę `[ImGuiDrawView showChange:true];`. Ta metoda w `ImGuiDrawView.mm` ustawia statyczną zmienną logiczną (prawdopodobnie o nazwie `MenDeal`) na `true`.
        *   Widok `ImGuiDrawView` (`_vna.view`) jest dodawany jako podwidok do widoku głównego kontrolera widoku aplikacji: `[[UIApplication sharedApplication].windows[0].rootViewController.view addSubview:_vna.view];`.
    *   **`-(void)tapIconView2` (Akcja dla podwójnego stuknięcia dwoma palcami):**
        *   Ta metoda jest wywoływana po wykryciu podwójnego stuknięcia dwoma palcami.
        *   Również zapewnia, że instancja `ImGuiDrawView` (`_vna`) istnieje.
        *   Wywołuje `[ImGuiDrawView showChange:false];`, ustawiając flagę `MenDeal` w `ImGuiDrawView.mm` na `false`.
        *   Podobnie jak `tapIconView`, dodaje `_vna.view` jako podwidok.

4.  **Kontrola Widoczności Menu (`ImGuiDrawView.mm`):**
    *   Klasa `ImGuiDrawView` zawiera rzeczywistą logikę renderowania ImGui w swojej metodzie `drawInMTKView:`.
    *   Ta metoda sprawdza stan statycznej zmiennej logicznej `MenDeal`. Jeśli `MenDeal` jest `true`, menu ImGui jest renderowane. Jeśli `false`, menu nie jest renderowane, skutecznie je ukrywając.
    *   Sam widok (`_vna.view`) może pozostać w hierarchii widoków, ale jego zawartość (menu) jest rysowana warunkowo na podstawie `MenDeal`.

## Jak Odtworzyć dla Niestandardowego Rysowania

Aby odtworzyć tę kontrolowaną gestami widoczność dla dowolnej niestandardowej treści, którą chcesz narysować na ekranie, wykonaj następujące kroki:

1.  **Utwórz Swój Niestandardowy Widok Nakładki:**
    *   Utwórz podklasę `UIView` (np. `MyCustomOverlayView`).
    *   Zaimplementuj jej logikę rysowania (np. w `drawRect:`) lub dodaj do niej podwidoki, aby wyświetlić żądaną treść.
    *   Dodaj metodę lub właściwość do kontrolowania jej widoczności, na przykład:
        ```objective-c
        // MyCustomOverlayView.h
        @interface MyCustomOverlayView : UIView
        @property (nonatomic, assign, getter=isVisible) BOOL visible;
        - (void)showView;
        - (void)hideView;
        @end

        // MyCustomOverlayView.m
        @implementation MyCustomOverlayView
        - (void)setVisible:(BOOL)visible {
            _visible = visible;
            self.hidden = !visible;
            // Lub wywołaj ponowne rysowanie, jeśli rysujesz niestandardowo, a widoczność na to wpływa
            // [self setNeedsDisplay]; 
        }
        - (void)showView {
            self.visible = YES;
        }
        - (void)hideView {
            self.visible = NO;
        }
        // ... twój kod rysujący ...
        @end
        ```

2.  **Utwórz Klasę Kontrolera Gestów:**
    *   Utwórz klasę Objective-C (np. `GestureController`). Ta klasa będzie zarządzać rozpoznawaczami gestów i widokiem nakładki.
    *   Zadeklaruj właściwość dla swojego niestandardowego widoku nakładki:
        ```objective-c
        // GestureController.h
        #import <UIKit/UIKit.h>
        #import "MyCustomOverlayView.h"

        @interface GestureController : NSObject
        @property (nonatomic, strong) MyCustomOverlayView *overlayView;
        + (instancetype)sharedController;
        - (void)setupGesturesAndOverlayInWindow:(UIWindow *)window; // Lub przekaż konkretny widok
        @end
        ```

3.  **Zainicjuj Nakładkę i Skonfiguruj Gesty:**
    *   W `GestureController.m`:
        ```objective-c
        // GestureController.m
        @implementation GestureController

        + (instancetype)sharedController {
            static GestureController *shared = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                shared = [[self alloc] init];
            });
            return shared;
        }

        - (void)setupGesturesAndOverlayInView:(UIView *)targetView {
            if (!self.overlayView) {
                self.overlayView = [[MyCustomOverlayView alloc] initWithFrame:targetView.bounds];
                self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                self.overlayView.visible = NO; // Zacznij ukryty
                [targetView addSubview:self.overlayView];
            }

            // Skonfiguruj podwójne stuknięcie trzema palcami, aby pokazać
            UITapGestureRecognizer *showGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleShowGesture:)];
            showGesture.numberOfTapsRequired = 2;
            showGesture.numberOfTouchesRequired = 3;
            [targetView addGestureRecognizer:showGesture];

            // Skonfiguruj podwójne stuknięcie dwoma palcami, aby ukryć
            UITapGestureRecognizer *hideGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleHideGesture:)];
            hideGesture.numberOfTapsRequired = 2;
            hideGesture.numberOfTouchesRequired = 2;
            [targetView addGestureRecognizer:hideGesture];
        }

        - (void)handleShowGesture:(UITapGestureRecognizer *)gesture {
            [self.overlayView showView];
            [self.overlayView.superview bringSubviewToFront:self.overlayView]; // Upewnij się, że jest na wierzchu
            NSLog(@"Wyzwalacz gestu pokaż");
        }

        - (void)handleHideGesture:(UITapGestureRecognizer *)gesture {
            [self.overlayView hideView];
            NSLog(@"Wyzwalacz gestu ukryj");
        }

        @end
        ```

4.  **Zintegruj z Twoją Aplikacją:**
    *   W swoim `AppDelegate` lub odpowiednim miejscu po skonfigurowaniu głównego interfejsu użytkownika (np. po załadowaniu widoku głównego kontrolera widoku):
        ```objective-c
        // AppDelegate.m (lub odpowiednik)
        #import "GestureController.h"

        - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
            // ... twoja istniejąca konfiguracja ...

            // Zakładając, że self.window to twoje główne UIWindow
            // Lub pobierz widok rootViewController:
            // UIView *targetView = self.window.rootViewController.view;
            // Często najlepiej jest dodawać globalne gesty do samego okna.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                 [[GestureController sharedController] setupGesturesAndOverlayInView:self.window];
            });

            return YES;
        }
        ```

**Kluczowe Kwestie do Rozważenia przy Replikacji:**

*   **Widok Docelowy dla Gestów:** Dodanie rozpoznawaczy gestów do `UIWindow` czyni je globalnymi. Jeśli dodasz je do konkretnego `UIView`, będą działać tylko wtedy, gdy ten widok (lub jego podwidoki) może odbierać zdarzenia dotykowe.
*   **Hierarchia Widoków dla Nakładki:** Dodanie `MyCustomOverlayView` do `UIWindow` umieści go ponad całą inną zawartością w tym oknie. Dodanie go do widoku konkretnego kontrolera widoku ograniczy jego zakres do tego kontrolera.
*   **Konflikty Gestów:** Jeśli inne części twojej aplikacji używają podobnych gestów, być może będziesz musiał zaimplementować metody `UIGestureRecognizerDelegate` do zarządzania interakcjami gestów (np. `gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:`).
*   **Timing:** Upewnij się, że widok, do którego dodajesz rozpoznawacze gestów, jest już częścią hierarchii widoków i ma ramkę. Użycie `dispatch_after` jak w oryginalnym kodzie lub konfiguracja w `viewDidAppear:` kontrolera widoku może pomóc to zapewnić.
*   **`JHPP currentViewController`:** Oryginalny kod używa niestandardowego narzędzia `JHPP`. Do ogólnej replikacji częściej stosuje się dołączanie gestów do `[UIApplication sharedApplication].keyWindow` lub `self.window.rootViewController.view`. Jeśli potrzebujesz dynamicznie znaleźć najwyższy kontroler widoku, musiałbyś zaimplementować tę logikę.

To podejście zapewnia solidny sposób na przełączanie widoczności niestandardowej treści na ekranie za pomocą gestów podwójnego stuknięcia wieloma palcami, podobnie jak w analizowanym projekcie.
