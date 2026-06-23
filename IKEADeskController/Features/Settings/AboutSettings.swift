import SwiftUI

struct AboutSettings: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                BrandMark(size: 56, cornerRadius: 14)
                VStack(alignment: .leading, spacing: 4) {
                    Text(BrandTheme.wordmark)
                        .font(.title3.weight(.semibold))
                    Text("\(AppConstants.appName) · v\(AppVersion.marketing)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .glassCard(contentPadding: 16, cornerRadius: 14)

            VStack(alignment: .leading, spacing: 8) {
                Link("GitHub Repository", destination: URL(string: AppConstants.githubURL)!)
                Text("Unofficial app for IKEA IDÅSEN / LINAK sit-stand desks. Not affiliated with or endorsed by IKEA or LINAK.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .glassCard(contentPadding: 16, cornerRadius: 14)
        }
    }
}
