import SwiftUI

struct DrawView: View {
    @StateObject private var viewModel: DrawViewModel
    var onBack: () -> Void
    
    init(artworkId: UUID? = nil, onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: DrawViewModel(artworkId: artworkId))
        self.onBack = onBack
    }
    
    var body: some View {
        ZStack {
            AppColors.drawBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Top Banner Area (Denim-blue #1E5068)
                BannerAdPlaceholder(height: 80)
                
                // 2. Canvas & Floating Top Controls
                ZStack(alignment: .top) {
                    // The Native Core Graphics Neon Canvas
                    NeonCanvasRepresentable(
                        currentTool: $viewModel.currentTool,
                        currentStyle: $viewModel.currentStyle,
                        currentColor: $viewModel.currentColor,
                        currentStrokeWidth: $viewModel.currentStrokeWidth,
                        currentAlpha: $viewModel.currentAlpha,
                        strokes: viewModel.strokes,
                        isReplaying: viewModel.isReplaying,
                        replayCompletedStrokes: viewModel.replayCompletedStrokes,
                        replayActiveStroke: viewModel.replayActiveStroke,
                        onStrokeAdded: { stroke in
                            viewModel.addStroke(stroke)
                        },
                        onBeginDrawing: {
                            if viewModel.showBrushPicker {
                                viewModel.showBrushPicker = false
                            }
                            if viewModel.showShareSubmenu {
                                viewModel.showShareSubmenu = false
                            }
                        },
                        onCanvasReady: { canvas in
                            viewModel.canvasView = canvas
                        }
                    )
                    .ignoresSafeArea(.all, edges: .horizontal)
                    
                    // Floating Top Buttons
                    HStack {
                        // Top-left: Coral Back button
                        CoralCircleButton(iconName: "chevron.backward", size: 44) {
                            viewModel.saveArtwork()
                            onBack()
                        }
                        
                        Spacer()
                        
                        // Top-right: Trash Button (or Exit replay X)
                        if viewModel.isReplaying {
                            CoralCircleButton(iconName: "xmark", size: 44) {
                                viewModel.exitReplay()
                            }
                        } else {
                            CoralCircleButton(iconName: "trash.fill", size: 44) {
                                viewModel.showClearAlert = true
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
                
                // 3. Bottom Controls Area
                if viewModel.isReplaying {
                    MoviePlaybackBar(
                        player: viewModel.player,
                        onExit: {
                            viewModel.exitReplay()
                        },
                        onRecordTapped: {
                            viewModel.exitReplay()
                            viewModel.showMovieExport = true
                        }
                    )
                } else {
                    VStack(spacing: 0) {
                        // Brush picker sheet when active
                        if viewModel.showBrushPicker {
                            BrushPickerSheet(
                                currentTool: $viewModel.currentTool,
                                currentStyle: $viewModel.currentStyle,
                                currentColor: $viewModel.currentColor,
                                currentStrokeWidth: $viewModel.currentStrokeWidth,
                                onClose: {
                                    viewModel.showBrushPicker = false
                                }
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        // 5 Round Buttons Toolbar
                        DrawingToolbarView(
                            currentTool: $viewModel.currentTool,
                            onBrushTap: {
                                viewModel.toggleBrushPicker()
                            },
                            onEraserTap: {
                                viewModel.toggleEraser()
                            },
                            onUndoTap: {
                                viewModel.undo()
                            },
                            onRedoTap: {
                                viewModel.redo()
                            },
                            onPlayTap: {
                                viewModel.startReplay()
                            },
                            onShareTap: {
                                viewModel.toggleShareSubmenu()
                            }
                        )
                    }
                }
            }
            
            // 4. Share Popup Submenu (matches video f_030.jpg)
            if viewModel.showShareSubmenu {
                ShareMenuOverlay(
                    onCameraTapped: {
                        viewModel.toastMessage = "Camera background feature coming soon!"
                    },
                    onMovieTapped: {
                        viewModel.showMovieExport = true
                    },
                    onSavePhotoTapped: {
                        viewModel.saveToPhotoAlbum()
                    },
                    onShareSheetTapped: {
                        viewModel.openShareSheet()
                    },
                    onDismiss: {
                        viewModel.showShareSubmenu = false
                    }
                )
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $viewModel.showMovieExport) {
            MovieExportView(strokes: viewModel.strokes) {
                viewModel.showMovieExport = false
            }
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            ShareActivityView(activityItems: viewModel.shareItems)
        }
        .alert("Clear Canvas?", isPresented: $viewModel.showClearAlert) {
            Button("Clear All", role: .destructive) {
                viewModel.clearCanvas()
                HapticManager.shared.warning()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to erase the whole canvas?")
        }
        .alert("Notice", isPresented: Binding(
            get: { viewModel.toastMessage != nil },
            set: { if !$0 { viewModel.toastMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.toastMessage ?? "")
        }
        .onDisappear {
            viewModel.saveArtwork()
        }
    }
}
