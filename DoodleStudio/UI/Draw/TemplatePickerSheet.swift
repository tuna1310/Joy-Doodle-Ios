import SwiftUI

// MARK: - TemplatePickerCategory
public enum TemplatePickerCategory: String, CaseIterable, Identifiable {
    case all = "all"
    case animals = "animals"
    case vehicles = "vehicles"
    case sea = "sea"
    case flowers = "flowers"
    case dinosaurs = "dinosaurs"
    case food = "food"
    case scenery = "scenery"
    case letters = "letters"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .all: return "⭐"
        case .animals: return "🐶"
        case .vehicles: return "🚗"
        case .sea: return "🌊"
        case .flowers: return "🌸"
        case .dinosaurs: return "🦖"
        case .food: return "🍎"
        case .scenery: return "🏡"
        case .letters: return "🔤"
        }
    }

    public var displayNameVi: String {
        switch self {
        case .all: return "Tất cả"
        case .animals: return "Động vật"
        case .vehicles: return "Phương tiện"
        case .sea: return "Biển"
        case .flowers: return "Hoa lá"
        case .dinosaurs: return "Khủng long"
        case .food: return "Trái cây"
        case .scenery: return "Phong cảnh"
        case .letters: return "Chữ cái"
        }
    }
}

// MARK: - TemplatePickerSheet
public struct TemplatePickerSheet: View {
    @ObservedObject var viewModel: DrawViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedCategory: TemplatePickerCategory = .all
    @State private var templates: [Template] = []

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    public var body: some View {
        ZStack {
            Color(UIColor(hex: 0xFF0F172A)).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text("🎨").font(.system(size: 22))
                            Text("Tranh tô màu")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("Chọn hình mẫu để tô màu neon rực rỡ")
                            .font(.system(size: 12))
                            .foregroundColor(Color(UIColor(hex: 0xFF94A3B8)))
                    }

                    Spacer()

                    Button(action: { dismiss() }) {
                        Text("✕")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color(UIColor(hex: 0xFF1E293B)))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 12)

                // Category Chips (Horizontal Scroll)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TemplatePickerCategory.allCases) { cat in
                            let isSelected = cat == selectedCategory
                            Button(action: {
                                HapticManager.shared.selectionChanged()
                                selectedCategory = cat
                            }) {
                                HStack(spacing: 4) {
                                    Text(cat.icon)
                                    Text(cat.displayNameVi)
                                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                }
                                .foregroundColor(isSelected ? Color(UIColor(hex: 0xFF0F172A)) : Color(UIColor(hex: 0xFFE2E8F0)))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    isSelected
                                        ? LinearGradient(colors: [AppColors.neonCyan, Color(UIColor(hex: 0xFF06B6D4))], startPoint: .leading, endPoint: .trailing)
                                        : LinearGradient(colors: [Color(UIColor(hex: 0xFF1E293B)), Color(UIColor(hex: 0xFF1E293B))], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(isSelected ? AppColors.neonCyan : Color(UIColor(hex: 0xFF334155)), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 14)

                // Templates Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        // 1. "Vẽ tự do" Option Card
                        Button(action: {
                            HapticManager.shared.impact()
                            viewModel.clearToBlankCanvas()
                            dismiss()
                        }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle().fill(Color(UIColor(hex: 0xFF334155))).frame(width: 56, height: 56)
                                    Text("✏️").font(.system(size: 26))
                                }
                                Text("Vẽ tự do")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Trang vẽ trắng")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(UIColor(hex: 0xFF94A3B8)))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 170)
                            .background(Color(UIColor(hex: 0xFF1E293B)))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(viewModel.templateId == nil ? AppColors.neonPink : Color(UIColor(hex: 0xFF334155)), lineWidth: 1.5)
                            )
                        }

                        // 2. Filtered Template Items
                        ForEach(filteredTemplates) { template in
                            let isCurrent = template.id == viewModel.templateId
                            TemplateCard(template: template, isCurrent: isCurrent) {
                                HapticManager.shared.impact()
                                viewModel.loadTemplate(template)
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            templates = TemplateRepository.shared.getTemplates()
        }
    }

    private var filteredTemplates: [Template] {
        if selectedCategory == .all {
            return templates
        }
        return templates.filter {
            $0.categoryId.lowercased() == selectedCategory.rawValue.lowercased() ||
            $0.category.lowercased() == selectedCategory.displayNameVi.lowercased()
        }
    }
}

// MARK: - TemplateCard
struct TemplateCard: View {
    let template: Template
    let isCurrent: Bool
    let action: () -> Void

    @State private var thumbnail: UIImage? = nil

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                // Image Box
                ZStack(alignment: .topTrailing) {
                    Color.black
                    if let img = thumbnail {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .padding(4)
                    } else {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }

                    // Category badge
                    Text(template.category)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(AppColors.neonCyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(UIColor(hex: 0xCC0F172A)))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(6)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Title
                Text(template.displayTitleVi)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                // Subtitle + Regions
                HStack {
                    Text(template.displayTitleEn)
                        .font(.system(size: 10))
                        .foregroundColor(Color(UIColor(hex: 0xFF94A3B8)))
                        .lineLimit(1)

                    Spacer()

                    if template.significantRegions > 0 {
                        Text("\(template.significantRegions) vùng")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppColors.neonYellow)
                    }
                }
            }
            .padding(8)
            .background(Color(UIColor(hex: 0xFF1E293B)))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isCurrent ? AppColors.neonCyan : Color(UIColor(hex: 0xFF334155)), lineWidth: isCurrent ? 2 : 1)
            )
        }
        .onAppear {
            thumbnail = TemplateRepository.shared.loadTemplateImage(template)
        }
    }
}

