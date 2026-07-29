import SwiftUI

struct TagFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let result = layout(
            proposalWidth: proposal.width ?? .infinity,
            subviews: subviews
        )
        return result.size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = layout(proposalWidth: bounds.width, subviews: subviews)
        for (index, point) in result.points.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y),
                anchor: .topLeading,
                proposal: .unspecified
            )
        }
    }

    private func layout(
        proposalWidth: CGFloat,
        subviews: Subviews
    ) -> (size: CGSize, points: [CGPoint]) {
        var points: [CGPoint] = []
        var cursor = CGPoint.zero
        var rowHeight: CGFloat = 0
        var contentWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if cursor.x > 0, cursor.x + size.width > proposalWidth {
                cursor.x = 0
                cursor.y += rowHeight + spacing
                rowHeight = 0
            }

            points.append(cursor)
            cursor.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            contentWidth = max(contentWidth, cursor.x - spacing)
        }

        return (
            CGSize(
                width: proposalWidth.isFinite ? proposalWidth : contentWidth,
                height: subviews.isEmpty ? 0 : cursor.y + rowHeight
            ),
            points
        )
    }
}
