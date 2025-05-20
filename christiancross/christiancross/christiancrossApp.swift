//
//  christiancrossApp.swift
//  christiancross
//
//  Creado por Inled Group.
// Licenciada bajo la Licencia Pública General de GNU G
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Crear el elemento en la barra de estado
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Configurar el icono de la cruz cristiana
        if let button = statusItem.button {
            button.image = drawCrossImage()
            button.imagePosition = .imageLeft
        }
        
        // Configurar el menú
        setupMenu()
    }
    
    func drawCrossImage() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Configurar el contexto de dibujo
        let context = NSGraphicsContext.current!.cgContext
        context.setFillColor(NSColor.white.cgColor)
        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(2.0)
        
        // Dibujar el trazo vertical de la cruz
        let verticalRect = CGRect(x: 9 - 1, y: 2, width: 2, height: 14)
        context.fill(verticalRect)
        
        // Dibujar el trazo horizontal de la cruz
        let horizontalRect = CGRect(x: 4, y: 9, width: 10, height: 2)
        context.fill(horizontalRect)
        
        image.unlockFocus()
        
        return image
    }
    func setupMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Acerca de Cruz Cristiana", action: #selector(showAboutWindow), keyEquivalent: "a"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Salir", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    var aboutWindow: AboutWindow?
    
    @objc func showAboutWindow() {
        // Si la ventana ya existe, la mostramos
        if let window = aboutWindow {
            window.makeKeyAndOrderFront(nil)
            return
        }
        
        // Si no existe, la creamos
        aboutWindow = AboutWindow()
        aboutWindow?.makeKeyAndOrderFront(nil)
    }
    
    // Clase personalizada para la ventana "Acerca de"
    class AboutWindow: NSWindow {
        init() {
            // Definir el tamaño de la ventana
            let windowSize = NSRect(x: 0, y: 0, width: 400, height: 300)
            let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable]
            
            super.init(contentRect: windowSize,
                       styleMask: styleMask,
                       backing: .buffered,
                       defer: false)
            
            // Configuración de la ventana
            self.title = "Acerca de Cruz Cristiana"
            self.center()
            self.isReleasedWhenClosed = false
            
            // Configurar el contenido
            setupContent()
        }
        
        private func setupContent() {
            // Crear un contenedor principal
            let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 500))
            contentView.wantsLayer = true
            

            
            // Añadir versión
            let versionLabel = NSTextField(labelWithString: "Versión 1.0")
            versionLabel.alignment = .center
            versionLabel.frame = NSRect(x: 20, y: 100, width: 360, height: 20)
            
            // Añadir descripción
            let descriptionText = "Muestra la cruz de Cristo en la barra de menús de MacOS."
            let descriptionLabel = NSTextField(wrappingLabelWithString: descriptionText)
            descriptionLabel.alignment = .center
            descriptionLabel.frame = NSRect(x: 20, y: 200, width: 360, height: 80)
            
            // Añadir créditos
            let creditsLabel = NSTextField(labelWithString: "Desarrollado por Inled Group como prueba de concepto")
            creditsLabel.alignment = .center
            creditsLabel.frame = NSRect(x: 20, y: 120, width: 360, height: 20)
            
            // Licencia GNU
            let licenseLink = NSTextField(labelWithString: "")
            licenseLink.isSelectable = true
            licenseLink.allowsEditingTextAttributes = true
            licenseLink.frame = NSRect(x: 20, y: 80, width: 360, height: 20)
            
            let attributedString = NSMutableAttributedString(string: "Licenciado bajo la licencia GNU GPL 3.0")
            attributedString.addAttribute(
                .link,
                value: "https://www.gnu.org/licenses/gpl-3.0.html#license-text",
                range: NSRange(location: 0, length: attributedString.length)
            )
            attributedString.addAttribute(.foregroundColor, value: NSColor.blue, range: NSRange(location: 0, length: attributedString.length))
            
            licenseLink.attributedStringValue = attributedString
            
            // Añadir componentes a la vista principal
            contentView.addSubview(descriptionLabel)
            contentView.addSubview(versionLabel)
            contentView.addSubview(creditsLabel)
            contentView.addSubview(licenseLink)
            
            // Establecer la vista de contenido
            self.contentView = contentView
        }
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
