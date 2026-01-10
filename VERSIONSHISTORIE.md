# VibeUp App - Versionshistorie und technische Dokumentation

## Projektübersicht

**VibeUp** ist eine Flutter-basierte Event-Management-Anwendung, die eine umfassende Plattform für Event-Organisatoren und Teilnehmer bietet. Die App nutzt Firebase als Backend-Technologie (Authentication, Firestore, Storage) und ermöglicht es Administratoren, Events zu erstellen und zu verwalten, während Benutzer Events entdecken, daran teilnehmen und interagieren können.

### Technologie-Stack
- **Frontend:** Flutter/Dart
- **Backend:** Firebase (Authentication, Cloud Firestore, Storage)
- **Hauptbibliotheken:**
  - `firebase_core` (v3.6.0) - Firebase-Kernfunktionalität
  - `firebase_auth` (v5.3.1) - Benutzerauthentifizierung
  - `cloud_firestore` (v5.4.4) - NoSQL-Datenbank
  - `firebase_storage` (v12.3.4) - Dateispeicherung
  - `qr_flutter` (v4.1.0) - QR-Code-Generierung
  - `image_picker` (v1.0.7) - Bildauswahl
  - `intl` (v0.19.0) - Datumsformatierung

### Datenbankstruktur (Firestore Collections)
- `users` - Benutzerprofile und Authentifizierungsdaten
- `events` - Event-Informationen
- `messages` - Chat-Nachrichten für Events
- `photos` - Event-Fotogalerie
- `tickets` - Ticket-Käufe
- `tables` - Tischreservierungen
- `menuItems` - Menüpositionen
- `orders` - Bestellungen

---

## Version 1: Grundlegende Event-Verwaltung

**Implementierungsdatum:** Initiale Version

### Funktionsumfang

#### 1. Benutzerauthentifizierung (lib/services/auth_service.dart)
Die App implementiert ein rollenbasiertes Authentifizierungssystem mit zwei Benutzertypen:

**Administrator (Developer-Rolle):**
- Rolle in Datenbank: `role: 'developer'`
- Kann Events erstellen, bearbeiten und löschen
- Zugriff auf Event-Analytics und Verwaltungsfunktionen
- Implementiert in: `auth_service.dart:28` (`isDeveloper` getter)

**Benutzer (User-Rolle):**
- Rolle in Datenbank: `role: 'user'`
- Kann Events anzeigen und daran teilnehmen
- Standardrolle bei Registrierung
- Implementiert in: `auth_service.dart:29` (`isUser` getter)

**Technische Implementierung:**
```dart
// Registrierung mit Rollenzuweisung (auth_service.dart:83-124)
Future<void> register({
  required String email,
  required String password,
  required String name,
  required String role, // 'user' oder 'developer'
}) async
```

Benutzerdaten werden in Firestore unter `users/{uid}` gespeichert:
- `uid` - Firebase Authentication User ID
- `email` - E-Mail-Adresse
- `name` - Anzeigename
- `role` - Benutzerrolle ('user' oder 'developer')
- `balance` - Guthaben (initial 0.0)
- `createdAt` - Erstellungszeitpunkt

#### 2. Event-Erstellung durch Administratoren (lib/screens/create_event_screen.dart, lib/services/event_service.dart)

**Event-Datenmodell** (lib/models/event_model.dart):
- `id` - Eindeutige Event-ID
- `name` - Event-Name
- `location` - Veranstaltungsort
- `description` - Beschreibung
- `dateTime` - Datum und Uhrzeit
- `category` - Kategorie (z.B. Musik, Sport, Kultur)
- `tags` - Schlagwörter für Filterung
- `isPublic` - Sichtbarkeit (öffentlich/privat)
- `creatorId` - Administrator-User-ID
- `creatorName` - Name des Erstellers
- `attendanceCount` - Anzahl der Teilnehmer
- `createdAt` / `updatedAt` - Zeitstempel

**Implementierung** (event_service.dart:29-42):
```dart
Future<String> createEvent(Event event) async
```
Events werden in der Firestore-Collection `events` gespeichert.

#### 3. Event-Anzeige für Benutzer

**Öffentliche Events** (event_service.dart:75-92):
```dart
Stream<List<Event>> getPublicEvents()
```
Filtert Events nach `isPublic: true` und sortiert sie chronologisch.

**Event-Details-Ansicht** (lib/screens/event_details_screen.dart):
- Zeigt alle Event-Informationen
- Datum, Uhrzeit, Ort, Beschreibung
- Kategorien und Tags
- Teilnehmerzahl

---

## Version 2: Interaktion und Wirtschaftssystem

**Implementierungsdatum:** Zweite Iteration

### Neue Funktionen

#### 1. Event-Teilnahme (lib/services/event_service.dart)

Benutzer können sich für Events anmelden. Die Teilnahme wird durch eine Sub-Collection verwaltet:
- Firestore-Pfad: `events/{eventId}/attendees/{userId}`
- Speichert User-ID, Name und Anmeldezeitpunkt
- Aktualisiert `attendanceCount` im Event-Dokument

**Implementierung** (event_service.dart):
```dart
Future<void> attendEvent(String eventId, String userId, String userName) async
Future<void> unattendEvent(String eventId, String userId) async
Stream<bool> isUserAttending(String eventId, String userId)
```

#### 2. Event-Chat-System (lib/services/chat_service.dart, lib/screens/chat_room_screen.dart)

Für jedes Event wird ein dedizierter Chat-Raum erstellt, in dem alle Teilnehmer kommunizieren können.

**Nachrichten-Datenmodell** (lib/models/message_model.dart):
- `id` - Nachrichten-ID
- `eventId` - Zugehöriges Event
- `userId` - Absender-ID
- `userName` - Anzeigename des Absenders
- `text` - Nachrichteninhalt
- `timestamp` - Sendezeitpunkt

**Chat-Funktionen** (chat_service.dart:29-59):
```dart
Future<void> sendMessage({
  required String eventId,
  required String userId,
  required String userName,
  required String text,
}) async

Stream<List<Message>> getEventMessages(String eventId)
Future<void> deleteMessage(String messageId) async
```

**Zugriffskontrolle:**
- Nur angemeldete Teilnehmer können Nachrichten senden
- Nachrichten werden in Echtzeit synchronisiert (Firestore Streams)
- Nachrichten werden chronologisch sortiert

#### 3. Monet-Balance-System (lib/services/auth_service.dart)

Jeder Benutzer erhält ein virtuelles Guthaben-Konto für In-App-Transaktionen.

**Balance-Verwaltung** (auth_service.dart:22, 212-251):
```dart
double _balance = 0.0;
double get balance => _balance;

Future<void> addMoney(double amount) async
Future<void> deductMoney(double amount) async
```

**Eigenschaften:**
- Initialer Betrag: 0.0 (bei Registrierung)
- Wird in Firestore unter `users/{uid}/balance` gespeichert
- Validierung bei Abbuchungen (Insufficient balance check)
- Automatische Synchronisation zwischen App und Datenbank

---

## Version 3: Medien und Ticketing

**Implementierungsdatum:** Dritte Iteration

### Neue Funktionen

#### 1. Event-Fotogalerie (lib/services/photo_service.dart, lib/screens/event_gallery_screen.dart)

Sowohl Administratoren als auch Benutzer können Fotos zu Events hochladen und teilen.

**Foto-Datenmodell** (lib/models/event_photo_model.dart):
- `id` - Foto-ID
- `eventId` - Zugehöriges Event
- `uploaderId` - Hochlader-User-ID
- `uploaderName` - Name des Hochladers
- `imageUrl` - Firebase Storage Download-URL
- `uploadedAt` - Upload-Zeitpunkt
- `isOrganizerPhoto` - Kennzeichnung für offizielle Event-Fotos (Admin)

**Upload-Funktionalität** (photo_service.dart:32-88):
```dart
Future<String> uploadPhoto({
  required String eventId,
  required String userId,
  required String userName,
  required dynamic file,
  required bool isOrganizerPhoto,
}) async
```

**Technische Details:**
- Speicherung in Firebase Storage unter `event_photos/{eventId}/{timestamp}.jpg`
- Unterstützung für Web (Uint8List) und Mobile (File)
- Metadaten in Firestore-Collection `photos`
- Echtzeit-Synchronisation der Bildergalerie

**Administratoren-Fotos:**
- Können als offizielle Event-Fotos markiert werden
- Werden auf Event-Detailseite prominent angezeigt
- Filter: `isOrganizerPhoto: true`

#### 2. Ticket-System mit QR-Code (lib/services/ticket_service.dart, lib/widgets/purchase_ticket_dialog.dart)

Benutzer können Tickets für Events kaufen, die als QR-Codes generiert werden.

**Ticket-Datenmodell** (lib/models/ticket_model.dart):
- `id` - Ticket-ID (dient als QR-Code-Daten)
- `eventId` - Zugehöriges Event
- `eventName` / `eventLocation` / `eventDateTime` - Event-Details
- `userId` - Käufer-ID
- `ticketType` - Typ: 'GA' (General Admission) oder 'VIP'
- `price` - Kaufpreis
- `purchasedAt` - Kaufzeitpunkt

**Ticket-Typen:**

1. **General Admission (GA):**
   - Standardticket
   - Preis: `event.ticketPrice`

2. **VIP-Ticket:**
   - Premium-Zugang
   - Preis: `event.ticketPriceVIP`
   - Optionale Zusatzfunktion

**Kaufprozess** (ticket_service.dart):
```dart
Future<String> purchaseTicket({
  required String eventId,
  required Event event,
  required String userId,
  required String ticketType,
  required double price,
}) async
```

**Ablauf:**
1. Preisvalidierung
2. Guthabenprüfung (`balance >= price`)
3. Guthaben-Abbuchung über `auth_service.deductMoney()`
4. Ticket-Erstellung in Firestore (`tickets` Collection)
5. QR-Code-Generierung mit Ticket-ID

**QR-Code-Implementierung** (main.dart:2164-2165):
```dart
QrImageView(
  data: _generateQRData(), // Ticket-ID + Event-Daten
  version: QrVersions.auto,
  size: 200.0,
)
```

**QR-Code-Daten-Format:**
```
TICKET:{ticketId}
EVENT:{eventId}
USER:{userId}
TYPE:{ticketType}
```

#### 3. Kostenlose Events

Events können auch kostenlos sein:
- `ticketPrice: null` und `ticketPriceVIP: null`
- Keine Zahlung erforderlich
- Ticket wird trotzdem generiert (für Zugangsnachweis)

---

## Version 4: Gastronomie und Tischservice

**Implementierungsdatum:** Vierte Iteration

### Neue Funktionen

#### 1. Menü-System (lib/services/menu_service.dart, lib/screens/menu_management_screen.dart)

Administratoren können für jedes Event ein digitales Menü erstellen.

**Menü-Datenmodell** (lib/models/menu_item_model.dart):
- `id` - Menüposition-ID
- `eventId` - Zugehöriges Event
- `name` - Produktname
- `category` - Kategorie
- `price` - Preis
- `description` - Produktbeschreibung (optional)
- `imageUrl` - Produktbild (optional)
- `isAvailable` - Verfügbarkeit
- `stockQuantity` - Lagerbestand

**Kategorien:**
- Champagne (Champagner)
- Vodka
- Whiskey
- Mixers (Mixer-Getränke)
- Food (Speisen)
- Weitere benutzerdefinierte Kategorien

**Menü-Verwaltung** (menu_service.dart):
```dart
Future<String> createMenuItem(MenuItem item) async
Future<void> updateMenuItem(String itemId, MenuItem item) async
Future<void> deleteMenuItem(String itemId) async
Stream<List<MenuItem>> getEventMenu(String eventId)
```

#### 2. Tischreservierungssystem (lib/services/table_service.dart, lib/screens/table_booking_screen.dart)

VIP-Tische können von Benutzern gebucht werden.

**Tisch-Datenmodell** (lib/models/table_model.dart):
- `id` - Tisch-ID
- `eventId` - Zugehöriges Event
- `tableNumber` - Tischnummer
- `capacity` - Sitzplatzkapazität
- `bookingPrice` - Reservierungsgebühr
- `location` - Bereich (z.B. 'VIP Section', 'Main Floor')
- `isBooked` - Buchungsstatus
- `bookedByUserId` / `bookedByUserName` - Buchungsdaten
- `bookedAt` - Buchungszeitpunkt
- `totalSpent` - Gesamtausgaben (Bestellungen)
- `totalDue` - Offener Betrag

**Buchungsprozess** (table_service.dart):
```dart
Future<void> bookTable({
  required String tableId,
  required String userId,
  required String userName,
  required double bookingPrice,
}) async
```

**Ablauf:**
1. Verfügbarkeitsprüfung (`isBooked: false`)
2. Guthabenprüfung
3. Buchungsgebühr-Abbuchung
4. Tisch-Reservierung mit User-Daten
5. Status-Update: `isBooked: true`

**Tisch-Verwaltung durch Administratoren** (lib/screens/table_management_screen.dart):
- Tische erstellen und löschen
- Kapazität und Preise festlegen
- Übersicht über alle Buchungen
- Manuelle Freigabe von Tischen

#### 3. Bestellsystem (lib/services/order_service.dart, lib/screens/order_cart_screen.dart)

Benutzer können vom Menü bestellen und direkt in der App bezahlen.

**Bestellungs-Datenmodell** (lib/models/table_order_model.dart):
- `id` - Bestellungs-ID
- `eventId` - Zugehöriges Event
- `tableId` / `tableNumber` - Tisch-Informationen
- `userId` / `userName` - Besteller
- `items` - Liste von Bestellpositionen
- `totalAmount` - Gesamtbetrag
- `status` - Status der Bestellung
- `isPaid` - Zahlungsstatus
- `orderedAt` / `deliveredAt` / `paidAt` - Zeitstempel

**Bestellposition** (OrderItem in table_order_model.dart):
- `menuItemId` - Referenz zum Menü-Item
- `name` - Produktname
- `price` - Einzelpreis
- `quantity` - Anzahl
- `specialInstructions` - Sonderwünsche (optional)
- `subtotal` - Zwischensumme (price × quantity)

**Bestellstatus-Workflow:**
1. `pending` - Neue Bestellung, wartet auf Bestätigung
2. `confirmed` - Von Admin bestätigt
3. `preparing` - In Zubereitung
4. `delivered` - Ausgeliefert
5. `paid` - Bezahlt (Abschluss)

**Bestellung erstellen** (order_service.dart):
```dart
Future<String> createOrder({
  required String eventId,
  required String tableId,
  required String tableNumber,
  required String userId,
  required String userName,
  required List<OrderItem> items,
  required double totalAmount,
}) async
```

**Zahlungsprozess** (order_service.dart):
```dart
Future<void> payOrder(String orderId, double amount) async
```

**Ablauf:**
1. Bestellung wird erstellt (Status: `pending`)
2. Admin sieht Bestellung im Dashboard
3. Admin aktualisiert Status (confirmed → preparing → delivered)
4. Benutzer zahlt in der App:
   - Guthabenprüfung
   - Abbuchung des Betrags
   - Status-Update: `isPaid: true`
   - `paidAt` Zeitstempel
5. Tisch-Update: `totalSpent` wird erhöht

#### 4. Bestellungs-Dashboard für Administratoren (lib/screens/order_dashboard_screen.dart)

Administratoren haben Zugriff auf ein Echtzeit-Dashboard:
- Alle offenen Bestellungen nach Tisch
- Status-Verwaltung
- Übersicht über Umsätze
- Filterung nach Event

---

## Zusätzliche Funktionen (alle Versionen)

### 1. Event-Analytics (lib/screens/event_analytics_screen.dart)

**Verfügbar für:** Administratoren

**Funktionen:**
- Ticket-Verkaufsstatistiken
  - Anzahl verkaufter Tickets (GA vs. VIP)
  - Gesamtumsatz aus Ticket-Verkäufen
  - Umsatzverteilung nach Ticket-Typ
- Echtzeit-Daten über Firestore Streams
- Visualisierung von Event-Performance

**Implementierung:**
```dart
Stream<List<Ticket>> getEventTickets(String eventId)
```

### 2. Einstellungen (lib/screens/settings_screen.dart)

**Benutzerprofil-Verwaltung:**
- Name ändern
- Passwort ändern (mit aktueller Passwort-Validierung)
- E-Mail-Anzeige

**App-Einstellungen:**
- Benachrichtigungen aktivieren/deaktivieren
  - Gespeichert in `users/{uid}/notificationsEnabled`
- Dark Mode aktivieren/deaktivieren
  - Gespeichert in `users/{uid}/darkModeEnabled`

**Implementierung:**
```dart
Future<void> _updateName() async
Future<void> _updatePassword() async
Future<void> _toggleNotifications(bool value) async
Future<void> _toggleDarkMode(bool value) async
```

### 3. Event-Kategorisierung und Filterung

**Kategorien:**
Events können verschiedenen Kategorien zugeordnet werden (z.B. Musik, Sport, Kultur, Nightlife)

**Tags:**
Flexible Schlagwörter für erweiterte Filterung und Suche

**Öffentlich/Privat:**
- Öffentliche Events: Sichtbar für alle Benutzer
- Private Events: Nur für eingeladene Benutzer (künftige Erweiterung)

### 4. Event-Suche und -Filterung

**Implementierung in main.dart:**
- Suche nach Event-Namen
- Filterung nach Kategorien
- Zeitbasierte Filterung (kommende Events)
- Sortierung nach Datum

### 5. Guthaben-Verwaltung

**Aufladen** (settings_screen.dart):
```dart
Future<void> _addMoney() async
```
Benutzer können Guthaben aufladen (Simulation, in Produktion: Payment Gateway Integration)

**Verwendung:**
- Ticket-Käufe
- Tischreservierungen
- Bestellungen

**Transparenz:**
- Aktueller Kontostand immer sichtbar
- Transaktionshistorie (künftige Erweiterung)

### 6. Mehrsprachigkeit (Vorbereitung)

Die App nutzt das `intl`-Package für Datumsformatierung, was die Grundlage für vollständige Internationalisierung bildet.

---

## Technische Architektur

### Services-Schicht

**AuthService** (lib/services/auth_service.dart):
- Benutzerauthentifizierung
- Rollen-Management
- Balance-Verwaltung
- Session-Management

**EventService** (lib/services/event_service.dart):
- Event CRUD-Operationen
- Teilnahme-Management
- Event-Suche und -Filterung

**ChatService** (lib/services/chat_service.dart):
- Nachrichten-Management
- Echtzeit-Synchronisation

**PhotoService** (lib/services/photo_service.dart):
- Bild-Upload (Firebase Storage)
- Galerie-Verwaltung
- Plattformübergreifende Unterstützung (Web/Mobile)

**TicketService** (lib/services/ticket_service.dart):
- Ticket-Verkauf
- QR-Code-Integration
- Benutzer-Tickets-Verwaltung

**MenuService** (lib/services/menu_service.dart):
- Menü-CRUD-Operationen
- Kategorie-Management
- Verfügbarkeitskontrolle

**TableService** (lib/services/table_service.dart):
- Tisch-Management
- Buchungs-System
- Ausgaben-Tracking

**OrderService** (lib/services/order_service.dart):
- Bestellungs-Management
- Status-Workflow
- Zahlungsabwicklung

### Datenmodelle

Alle Modelle (lib/models/) implementieren:
- `toMap()` - Konvertierung zu Firestore-kompatiblen Maps
- `fromFirestore()` - Factory-Konstruktor für Firestore-Dokumente
- `copyWith()` - Immutable Update-Pattern (wo anwendbar)

### Screen-Architektur

Die App folgt einem modularen Screen-Design:
- **Authentication Screens:** Login, Registrierung
- **Main Screens:** Event-Liste, Event-Details
- **Chat Screen:** Event-Chat
- **Gallery Screen:** Event-Fotogalerie
- **Ticket Screen:** Meine Tickets mit QR-Codes
- **Admin Screens:** Event-Erstellung, Analytics, Menü-Verwaltung, Tisch-Verwaltung, Bestellungs-Dashboard
- **Settings Screen:** Benutzerprofil und App-Einstellungen

### State Management

Die App nutzt:
- **ChangeNotifier:** Für Service-Klassen
- **StatefulWidget:** Für UI-State
- **StreamBuilder:** Für Echtzeit-Daten von Firestore

---

## Sicherheit und Datenschutz

### Firebase Security Rules (Empfohlen)

**Authentifizierung:**
- Alle Datenbank-Operationen erfordern Authentifizierung
- Rollenbasierte Zugriffskontrolle

**Firestore Rules (Beispiel):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User-Dokumente: Nur eigene Daten lesbar/schreibbar
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }

    // Events: Öffentlich lesbar, nur Ersteller kann schreiben
    match /events/{eventId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null &&
                       request.resource.data.creatorId == request.auth.uid;
      allow update, delete: if request.auth.uid == resource.data.creatorId;
    }

    // Tickets: Nur eigene Tickets lesbar
    match /tickets/{ticketId} {
      allow read: if request.auth != null &&
                     request.auth.uid == resource.data.userId;
      allow write: if false; // Nur über Server-Code
    }
  }
}
```

**Storage Rules:**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /event_photos/{eventId}/{filename} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### Build-Konfiguration

**Android** (android/app/build.gradle):
- minSdkVersion: 21
- targetSdkVersion: 34

**iOS** (ios/Podfile):
- iOS 12.0+

### Initialisierung (lib/main.dart)

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

## Zusammenfassung der Versionen

| Version | Hauptfunktionen | Dateien (Haupt) |
|---------|----------------|-----------------|
| **V1** | Authentication, Event CRUD, Rollen-System | auth_service.dart, event_service.dart, event_model.dart |
| **V2** | Event-Teilnahme, Chat, Balance-System | chat_service.dart, message_model.dart, auth_service.dart (balance) |
| **V3** | Fotogalerie, Tickets, QR-Codes | photo_service.dart, ticket_service.dart, event_photo_model.dart, ticket_model.dart |
| **V4** | Menü, Tischreservierung, Bestellsystem, Zahlungen | menu_service.dart, table_service.dart, order_service.dart, menu_item_model.dart, table_model.dart, table_order_model.dart |

---


**Projektstruktur:**
```
lib/
├── models/          # Datenmodelle
├── screens/         # UI-Screens
├── services/        # Business Logic
├── widgets/         # Wiederverwendbare Komponenten
├── firebase_options.dart
└── main.dart       # App-Entry-Point
```
