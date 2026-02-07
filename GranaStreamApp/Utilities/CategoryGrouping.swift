import Foundation

struct CategorySection: Identifiable {
    let id: String
    let title: String
    let parent: CategoryResponseDto?
    let children: [CategoryResponseDto]
}

func groupCategoriesForList(_ categories: [CategoryResponseDto]) -> (sections: [CategorySection], leafParents: [CategoryResponseDto]) {
    let parents = categories.filter { $0.parentCategoryId == nil }
    let children = categories.filter { $0.parentCategoryId != nil }
    let parentsById = Dictionary(uniqueKeysWithValues: parents.map { ($0.id, $0) })

    let sortedParents = parents.sorted { lhs, rhs in
        if lhs.sortOrder == rhs.sortOrder {
            return (lhs.name ?? "").localizedCaseInsensitiveCompare(rhs.name ?? "") == .orderedAscending
        }
        return lhs.sortOrder < rhs.sortOrder
    }

    var childrenByParent: [String: [CategoryResponseDto]] = [:]
    var orphanChildren: [CategoryResponseDto] = []

    for child in children {
        guard let parentId = child.parentCategoryId, let parent = parentsById[parentId] else {
            orphanChildren.append(child)
            continue
        }

        guard typesAreCompatible(parentType: parent.categoryType, childType: child.categoryType) else {
            orphanChildren.append(child)
            continue
        }

        childrenByParent[parentId, default: []].append(child)
    }

    var sections: [CategorySection] = []
    var leafParents: [CategoryResponseDto] = []

    for parent in sortedParents {
        let childrenForParent = childrenByParent[parent.id] ?? []
        if childrenForParent.isEmpty {
            leafParents.append(parent)
        } else {
            let sortedChildren = childrenForParent.sorted { lhs, rhs in
                if lhs.sortOrder == rhs.sortOrder {
                    return (lhs.name ?? "").localizedCaseInsensitiveCompare(rhs.name ?? "") == .orderedAscending
                }
                return lhs.sortOrder < rhs.sortOrder
            }
            let title = parent.name ?? "Categoria"
            sections.append(CategorySection(id: parent.id, title: title, parent: parent, children: sortedChildren))
        }
    }

    if !orphanChildren.isEmpty {
        let sortedOrphans = orphanChildren.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return (lhs.name ?? "").localizedCaseInsensitiveCompare(rhs.name ?? "") == .orderedAscending
            }
            return lhs.sortOrder < rhs.sortOrder
        }
        sections.append(CategorySection(id: "others", title: "Outras", parent: nil, children: sortedOrphans))
    }

    return (sections: sections, leafParents: leafParents)
}

private func typesAreCompatible(parentType: CategoryType?, childType: CategoryType?) -> Bool {
    guard let parentType, let childType else {
        return false
    }

    return parentType == childType
}

func groupCategoriesForPicker(_ categories: [CategoryResponseDto], transactionType: TransactionType) -> [CategorySection] {
    let children = categories.filter { $0.parentCategoryId != nil }
    let parents = categories.filter { $0.parentCategoryId == nil }
    let parentIdsWithChildren = Set(children.compactMap { $0.parentCategoryId })
    let leafParents = parents.filter { !parentIdsWithChildren.contains($0.id) }

    let allowedTypes: Set<CategoryType> = {
        switch transactionType {
        case .income:
            return [.income, .both]
        case .expense:
            return [.expense, .both]
        case .transfer:
            return []
        }
    }()

    let filteredChildren = children.filter { category in
        guard let type = category.categoryType else { return false }
        return allowedTypes.contains(type)
    }

    let filteredLeafParents = leafParents.filter { category in
        guard let type = category.categoryType else { return false }
        return allowedTypes.contains(type)
    }

    var parentsById: [String: CategoryResponseDto] = [:]
    for parent in parents {
        parentsById[parent.id] = parent
    }

    let grouped = Dictionary(grouping: filteredChildren, by: { $0.parentCategoryId ?? "" })

    var sections: [CategorySection] = []
    var otherItems: [CategoryResponseDto] = []

    for (parentId, items) in grouped {
        if let parent = parentsById[parentId] {
            let sortedChildren = items.sorted { lhs, rhs in
                if lhs.sortOrder == rhs.sortOrder {
                    return (lhs.name ?? "").localizedCaseInsensitiveCompare(rhs.name ?? "") == .orderedAscending
                }
                return lhs.sortOrder < rhs.sortOrder
            }
            let title = parent.name ?? "Categoria"
            sections.append(CategorySection(id: parent.id, title: title, parent: parent, children: sortedChildren))
        } else {
            otherItems.append(contentsOf: items)
        }
    }

    otherItems.append(contentsOf: filteredLeafParents)

    if !otherItems.isEmpty {
        let sortedOthers = otherItems.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return (lhs.name ?? "").localizedCaseInsensitiveCompare(rhs.name ?? "") == .orderedAscending
            }
            return lhs.sortOrder < rhs.sortOrder
        }
        sections.append(CategorySection(id: "others", title: "Outras", parent: nil, children: sortedOthers))
    }

    return sections.sorted { lhs, rhs in
        if lhs.id == "others" { return false }
        if rhs.id == "others" { return true }
        let lhsOrder = lhs.parent?.sortOrder ?? Int.max
        let rhsOrder = rhs.parent?.sortOrder ?? Int.max
        if lhsOrder == rhsOrder {
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
        return lhsOrder < rhsOrder
    }
}
