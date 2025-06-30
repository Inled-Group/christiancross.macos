import Cocoa
import SwiftUI
import AVFoundation
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var helpWindow: HelpWindow?
    var aboutWindow: AboutWindow?
    var radioPlayer: RadioPlayer!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Remove or comment out if NSApp.disableRelaunchOnLogin() is not implemented
        // NSApp.disableRelaunchOnLogin()
        
        // Request notification permissions (for macOS 10.14+)
        if #available(macOS 10.14, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error = error {
                    print("Error requesting notification permissions: \(error)")
                }
            }
        }
        
        // Initialize radio player
        radioPlayer = RadioPlayer()
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Set cross icon
        if let button = statusItem.button {
            button.image = drawCrossImage()
            button.imagePosition = .imageLeft
        }
        
        // Set up menu
        setupMenu()
        
        // Check for updates on launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            UpdateManager.shared.checkForUpdatesWithUserPreferences()
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return false
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        radioPlayer.stop()
    }

    @objc func showHelpWindow() {
        if let window = helpWindow {
            window.close()
        }
        helpWindow = HelpWindow()
        helpWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func drawCrossImage() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()
        let context = NSGraphicsContext.current!.cgContext
        context.setFillColor(NSColor.white.cgColor)
        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(2.0)
        let verticalRect = CGRect(x: 9 - 1, y: 2, width: 2, height: 14)
        context.fill(verticalRect)
        let horizontalRect = CGRect(x: 4, y: 9, width: 10, height: 2)
        context.fill(horizontalRect)
        image.unlockFocus()
        return image
    }
    
    func setupMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Acerca de Cruz Cristiana", action: #selector(showAboutWindow), keyEquivalent: "a"))
        menu.addItem(NSMenuItem.separator())
        let radioMenuItem = NSMenuItem(title: "Radio María", action: nil, keyEquivalent: "")
        let radioSubmenu = NSMenu(title: "Radio María")
        let playItem = NSMenuItem(title: "▶️ Reproducir", action: #selector(playRadio), keyEquivalent: "p")
        let stopItem = NSMenuItem(title: "⏹️ Detener", action: #selector(stopRadio), keyEquivalent: "s")
        radioSubmenu.addItem(playItem)
        radioSubmenu.addItem(stopItem)
        radioMenuItem.submenu = radioSubmenu
        menu.addItem(radioMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Buscar actualizaciones...", action: #selector(checkForUpdatesManually), keyEquivalent: "u"))
        menu.addItem(NSMenuItem(title: "Ayuda", action: #selector(showHelpWindow), keyEquivalent: "h"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Salir", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    @objc func playRadio() {
        radioPlayer.play()
        updateMenuItems()
    }
    
    @objc func stopRadio() {
        radioPlayer.stop()
        updateMenuItems()
    }
    
    func updateMenuItems() {
        guard let menu = statusItem.menu else { return }
        for item in menu.items {
            if item.title == "Radio María", let submenu = item.submenu {
                for subItem in submenu.items {
                    if subItem.title.contains("Reproducir") {
                        subItem.title = radioPlayer.isPlaying ? "▶️ Reproduciendo..." : "▶️ Reproducir"
                        subItem.isEnabled = !radioPlayer.isPlaying
                    } else if subItem.title.contains("Detener") {
                        subItem.isEnabled = radioPlayer.isPlaying
                    }
                }
            }
        }
    }
    
    @objc func checkForUpdatesManually() {
        UpdateManager.shared.checkForUpdates { hasUpdate, release in
            DispatchQueue.main.async {
                if hasUpdate, let release = release {
                    UpdateManager.shared.showUpdateAlert(for: release)
                } else {
                    let alert = NSAlert()
                    alert.messageText = "No hay actualizaciones"
                    alert.informativeText = "Ya tienes la versión más reciente de Cruz Cristiana."
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }
    }
    
    @objc func showAboutWindow() {
        if let window = aboutWindow {
            window.close()
        }
        aboutWindow = AboutWindow()
        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    class AboutWindow: NSWindow {
        init() {
            let windowSize = NSRect(x: 0, y: 0, width: 450, height: 350)
            let styleMask: NSWindow.StyleMask = [.titled, .closable]
            super.init(contentRect: windowSize, styleMask: styleMask, backing: .buffered, defer: false)
            self.title = "Acerca de Cruz Cristiana"
            self.center()
            self.isReleasedWhenClosed = false
            self.restorationClass = nil
            self.isRestorable = false
            setupContent()
        }
        
        private func setupContent() {
            let contentView = NSView(frame: self.contentView?.bounds ?? self.frame)
            contentView.wantsLayer = true
            contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            let logoSize: CGFloat = 60
            let logoView = NSView(frame: NSRect(x: (450 - logoSize) / 2, y: 240, width: logoSize, height: logoSize))
            logoView.wantsLayer = true
            let logoLayer = CALayer()
            logoLayer.frame = logoView.bounds
            logoLayer.backgroundColor = NSColor.systemBlue.cgColor
            logoLayer.cornerRadius = logoSize / 8
            let crossLayer = CAShapeLayer()
            let crossPath = NSBezierPath()
            crossPath.move(to: NSPoint(x: logoSize/2 - 3, y: 10))
            crossPath.line(to: NSPoint(x: logoSize/2 + 3, y: 10))
            crossPath.line(to: NSPoint(x: logoSize/2 + 3, y: logoSize - 10))
            crossPath.line(to: NSPoint(x: logoSize/2 - 3, y: logoSize - 10))
            crossPath.close()
            crossPath.move(to: NSPoint(x: 15, y: logoSize/2 - 3))
            crossPath.line(to: NSPoint(x: logoSize - 15, y: logoSize/2 - 3))
            crossPath.line(to: NSPoint(x: logoSize - 15, y: logoSize/2 + 3))
            crossPath.line(to: NSPoint(x: 15, y: logoSize/2 + 3))
            crossPath.close()
            crossLayer.path = crossPath.cgPath
            crossLayer.fillColor = NSColor.white.cgColor
            logoLayer.addSublayer(crossLayer)
            logoView.layer?.addSublayer(logoLayer)
            let titleLabel = NSTextField(labelWithString: "Cruz Cristiana")
            titleLabel.font = NSFont.boldSystemFont(ofSize: 24)
            titleLabel.alignment = .center
            titleLabel.textColor = .labelColor
            titleLabel.frame = NSRect(x: 20, y: 200, width: 410, height: 30)
            let versionLabel = NSTextField(labelWithString: "Versión 1.1.0")
            versionLabel.font = NSFont.systemFont(ofSize: 14)
            versionLabel.alignment = .center
            versionLabel.textColor = .secondaryLabelColor
            versionLabel.frame = NSRect(x: 20, y: 175, width: 410, height: 20)
            let descriptionText = "Muestra la cruz de Cristo en la barra de menús de macOS\ny permite escuchar Radio María."
            let descriptionLabel = NSTextField(wrappingLabelWithString: descriptionText)
            descriptionLabel.font = NSFont.systemFont(ofSize: 13)
            descriptionLabel.alignment = .center
            descriptionLabel.textColor = .labelColor
            descriptionLabel.frame = NSRect(x: 40, y: 125, width: 370, height: 40)
            let creditsLabel = NSTextField(labelWithString: "Desarrollado por Inled Group")
            creditsLabel.font = NSFont.systemFont(ofSize: 12)
            creditsLabel.alignment = .center
            creditsLabel.textColor = .secondaryLabelColor
            creditsLabel.frame = NSRect(x: 20, y: 100, width: 410, height: 20)
            let websiteLink = NSTextField(labelWithString: "")
            websiteLink.isSelectable = true
            websiteLink.allowsEditingTextAttributes = true
            websiteLink.frame = NSRect(x: 20, y: 75, width: 410, height: 20)
            websiteLink.alignment = .center
            let websiteAttributedString = NSMutableAttributedString(string: "www.inled.es")
            websiteAttributedString.addAttribute(
                .link,
                value: "https://www.inled.es",
                range: NSRange(location: 0, length: websiteAttributedString.length)
            )
            websiteAttributedString.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: NSRange(location: 0, length: websiteAttributedString.length))
            websiteAttributedString.addAttribute(.font, value: NSFont.systemFont(ofSize: 12), range: NSRange(location: 0, length: websiteAttributedString.length))
            websiteLink.attributedStringValue = websiteAttributedString
            let licenseLink = NSTextField(labelWithString: "")
            licenseLink.isSelectable = true
            licenseLink.allowsEditingTextAttributes = true
            licenseLink.frame = NSRect(x: 20, y: 50, width: 410, height: 20)
            licenseLink.alignment = .center
            let licenseAttributedString = NSMutableAttributedString(string: "Licenciado bajo GNU GPL 3.0")
            licenseAttributedString.addAttribute(
                .link,
                value: "https://www.gnu.org/licenses/gpl-3.0.html#license-text",
                range: NSRange(location: 0, length: licenseAttributedString.length)
            )
            licenseAttributedString.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: NSRange(location: 0, length: licenseAttributedString.length))
            licenseAttributedString.addAttribute(.font, value: NSFont.systemFont(ofSize: 11), range: NSRange(location: 0, length: licenseAttributedString.length))
            licenseLink.attributedStringValue = licenseAttributedString
            contentView.addSubview(logoView)
            contentView.addSubview(titleLabel)
            contentView.addSubview(versionLabel)
            contentView.addSubview(descriptionLabel)
            contentView.addSubview(creditsLabel)
            contentView.addSubview(websiteLink)
            contentView.addSubview(licenseLink)
            self.contentView = contentView
        }
    }
    
    class HelpWindow: NSWindow {
        init() {
            let windowSize = NSRect(x: 0, y: 0, width: 600, height: 500)
            let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
            super.init(contentRect: windowSize, styleMask: styleMask, backing: .buffered, defer: false)
            self.title = "Ayuda - Cruz Cristiana"
            self.center()
            self.isReleasedWhenClosed = false
            self.minSize = NSSize(width: 500, height: 400)
            self.restorationClass = nil
            self.isRestorable = false
            setupContent()
        }
        
        private func setupContent() {
            let scrollView = NSScrollView(frame: self.contentView?.bounds ?? self.frame)
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = false
            scrollView.autohidesScrollers = true
            scrollView.autoresizingMask = [.width, .height]
            scrollView.borderType = .noBorder
            let textView = NSTextView()
            textView.isEditable = false
            textView.isSelectable = true
            textView.isRichText = true
            textView.font = NSFont.systemFont(ofSize: 13)
            textView.textColor = .labelColor
            textView.backgroundColor = .textBackgroundColor
            textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width - 40, height: CGFloat.greatestFiniteMagnitude)
            textView.textContainer?.widthTracksTextView = true
            textView.textContainerInset = NSSize(width: 20, height: 20)
            let helpText = """
            CRUZ CRISTIANA - GUÍA DE AYUDA

            ¿Qué es Cruz Cristiana?
            Cruz Cristiana es una aplicación sencilla que muestra el símbolo de la cruz cristiana en la barra de menús de macOS, sirviendo como un recordatorio visual de la fe cristiana y permitiendo escuchar Radio María.

            ¿Cómo usar la aplicación?

            1. INICIAR LA APLICACIÓN
            • Al abrir Cruz Cristiana, verás una pequeña cruz blanca en la barra de menús superior
            • La aplicación se ejecuta en segundo plano sin interferir con otras aplicaciones

            2. ACCEDER AL MENÚ
            • Haz clic en el icono de la cruz en la barra de menús
            • Se desplegará un menú con las siguientes opciones:
              - Acerca de Cruz Cristiana
              - Radio María (con submenú)
              - Buscar actualizaciones
              - Ayuda (esta ventana)
              - Salir

            3. RADIO MARÍA
            • Desde el menú "Radio María" puedes:
              - Reproducir: Inicia la transmisión de Radio María
              - Detener: Para la reproducción de radio
            • La radio continúa reproduciéndose mientras la aplicación esté abierta
            • Se requiere conexión a internet para escuchar la radio

            4. ATAJOS DE TECLADO
            • Cmd + A: Abrir ventana "Acerca de"
            • Cmd + P: Reproducir Radio María
            • Cmd + S: Detener Radio María
            • Cmd + U: Buscar actualizaciones
            • Cmd + H: Abrir esta ayuda
            • Cmd + Q: Salir de la aplicación

            5. ACTUALIZACIONES
            • La aplicación busca actualizaciones automáticamente al iniciar
            • También puedes buscar actualizaciones manualmente desde el menú

            PREGUNTAS FRECUENTES

            P: ¿La aplicación consume muchos recursos?
            R: La aplicación es ligera, pero reproducir radio streaming requiere ancho de banda y algo de procesamiento de audio.

            P: ¿Cómo puedo hacer que la aplicación se inicie automáticamente?
            R: Puedes añadir Cruz Cristiana a los elementos de inicio de sesión en Preferencias del Sistema > Usuarios y grupos > Elementos de inicio de sesión.

            P: ¿La radio se puede escuchar en segundo plano?
            R: Sí, Radio María continuará reproduciéndose aunque uses otras aplicaciones.

            P: ¿Qué hago si la radio no se reproduce?
            R: Verifica tu conexión a internet. Si el problema persiste, intenta detener y volver a reproducir.

            P: ¿La aplicación recopila datos personales?
            R: No, Cruz Cristiana no recopila, almacena ni transmite ningún dato personal.

            SOLUCIÓN DE PROBLEMAS

            Si la cruz no aparece en la barra de menús:
            • Verifica que la aplicación esté en ejecución
            • Reinicia la aplicación
            • Si el problema persiste, reinicia tu Mac

            Si la radio no reproduce:
            • Verifica tu conexión a internet
            • Intenta detener y volver a reproducir
            • Reinicia la aplicación si es necesario

            Si las actualizaciones no funcionan:
            • Verifica tu conexión a internet
            • Intenta buscar actualizaciones manualmente

            INFORMACIÓN TÉCNICA

            • Versión: 1.1.0
            • Compatibilidad: macOS 11.0 o superior
            • Desarrollador: Inled Group
            • Licencia: GNU GPL 3.0
            • Radio: Radio María España
            • Sitio web: www.inled.es

            CONTACTO Y SOPORTE

            Para reportar problemas o sugerir mejoras, puedes contactar al desarrollador a través de los canales oficiales de Inled Group en www.inled.es.

            Esta aplicación fue desarrollada como una demostración de concepto para mostrar cómo crear aplicaciones de barra de menús en macOS con Swift.
            """
            textView.string = helpText
            scrollView.documentView = textView
            self.contentView = scrollView
        }
    }
}

// NSBezierPath to CGPath conversion helper
extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [NSPoint](repeating: .zero, count: 3)
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                break
            }
        }
        return path
    }
}

class RadioPlayer: NSObject {
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private let radioURL = "https://dreamsiteradiocp4.com/proxy/rmspain1?mp=/stream/1/;.mp3"
    private var isObserving = false

    var isPlaying: Bool {
        return player?.timeControlStatus == .playing
    }

    override init() {
        super.init()
    }

    func play() {
        if isPlaying { return }
        guard let url = URL(string: radioURL) else {
            showError("URL de radio inválida")
            return
        }
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        playerItem?.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        isObserving = true
        player?.play()
        showNotification("Radio María", "Iniciando reproducción...")
    }

    func stop() {
        player?.pause()
        player = nil
        if isObserving, let item = playerItem {
            item.removeObserver(self, forKeyPath: "status")
            isObserving = false
        }
        playerItem = nil
        showNotification("Radio María", "Reproducción detenida")
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let playerItem = object as? AVPlayerItem {
                switch playerItem.status {
                case .readyToPlay:
                    showNotification("Radio María", "Conectado y reproduciendo")
                case .failed:
                    showError("Error al conectar con Radio María")
                    stop()
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    private func showNotification(_ title: String, _ message: String) {
        DispatchQueue.main.async {
            if #available(macOS 10.14, *) {
                let center = UNUserNotificationCenter.current()
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = message
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                center.add(request, withCompletionHandler: nil)
            } else {
                let notification = NSUserNotification()
                notification.title = title
                notification.informativeText = message
                notification.soundName = nil
                NSUserNotificationCenter.default.deliver(notification)
            }
        }
    }

    private func showError(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Error de Radio María"
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    deinit {
        stop()
    }
}

@main
struct CruzCristianaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
