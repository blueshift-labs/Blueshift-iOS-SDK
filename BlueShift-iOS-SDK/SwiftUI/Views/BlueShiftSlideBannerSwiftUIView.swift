//
//  BlueShiftSlideBannerSwiftUIView.swift
//  BlueShift-iOS-SDK
//
//  Super simple banner for all notifications (iOS 13+)
//

import SwiftUI

/// Simple slide-in banner view
@available(iOS 13.0, *)
struct BlueShiftSlideBannerSwiftUIView: View {
    
    @ObservedObject var viewModel: BlueShiftInAppViewModel
    @State private var offset: CGFloat = -200
    
    var body: some View {
        VStack {
            if isTopPosition {
                bannerContent
                    .offset(y: viewModel.isPresented ? 0 : offset)
                Spacer()
            } else {
                Spacer()
                bannerContent
                    .offset(y: viewModel.isPresented ? 0 : -offset)
            }
        } 
        .onAppear {
            withAnimation(.spring()) {
                offset = 0
            }
            
            // Auto-dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                viewModel.dismiss()
            }
        }
    }
    
    // MARK: - Banner Content
    
    private var bannerContent: some View {
        HStack(spacing: 12) {
            // Icon
            if let iconURL = viewModel.iconURL {
                RemoteImageView(url: iconURL, width: 50, height: 50) {
                    AnyView(defaultIcon)
                }
            } else {
                defaultIcon
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                if let title = viewModel.title {
                    Text(title)
                        .font(.headline)
                        .lineLimit(2)
                }
                
                if let message = viewModel.message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
            }
            
            Spacer()
            
            // Close button
            Button(action: { viewModel.dismiss() }) {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
                    .padding(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding()
        .onTapGesture {
            viewModel.dismiss()
        }
    }
    
    private var defaultIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
            
            Image(systemName: "bell.fill")
                .foregroundColor(.blue)
        }
    }
    
    private var isTopPosition: Bool {
        return true  // Always show at top for simplicity
    }
}
