import SwiftUI

struct VUMeter: View {
    let level: Float
    let label: String
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // Background
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    
                    // Level indicator
                    Rectangle()
                        .fill(levelColor)
                        .frame(height: geometry.size.height * CGFloat(level))
                }
            }
            .frame(width: 20)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var levelColor: Color {
        if level > 0.8 {
            return .red
        } else if level > 0.5 {
            return .yellow
        } else {
            return .green
        }
    }
}

#Preview {
    HStack {
        VUMeter(level: 0.7, label: "Zoom")
        VUMeter(level: 0.3, label: "Mic")
    }
    .frame(height: 100)
    .padding()
} 