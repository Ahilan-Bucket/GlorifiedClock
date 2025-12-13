
//
//  SyncedScrollView.swift
//  GlorifiedClock
//

import SwiftUI
import UIKit

// MARK: - Synchronized Scroll View

struct SyncedScrollView<Content: View>: UIViewRepresentable {
    let content: Content
    @ObservedObject var coordinator: ScrollSyncCoordinator
    let id: String
    
    init(id: String, coordinator: ScrollSyncCoordinator, @ViewBuilder content: () -> Content) {
        self.id = id
        self.coordinator = coordinator
        self.content = content()
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = true
        scrollView.alwaysBounceHorizontal = true
        
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            hostingController.view.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        context.coordinator.scrollView = scrollView
        context.coordinator.hostingController = hostingController
        
        return scrollView
    }
    
    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.hostingController?.rootView = content
        
        if !context.coordinator.isScrolling {
            coordinator.isInternalUpdate = true
            scrollView.contentOffset.x = coordinator.scrollOffset
            coordinator.isInternalUpdate = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(id: id, syncCoordinator: coordinator)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        let id: String
        let syncCoordinator: ScrollSyncCoordinator
        weak var scrollView: UIScrollView?
        var hostingController: UIHostingController<Content>?
        var isScrolling = false
        
        init(id: String, syncCoordinator: ScrollSyncCoordinator) {
            self.id = id
            self.syncCoordinator = syncCoordinator
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard !syncCoordinator.isInternalUpdate else { return }
            
            if scrollView.isDragging || scrollView.isDecelerating {
                isScrolling = true
                syncCoordinator.scrollOffset = scrollView.contentOffset.x
            }
        }
        
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate {
                isScrolling = false
            }
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            isScrolling = false
        }
    }
}
