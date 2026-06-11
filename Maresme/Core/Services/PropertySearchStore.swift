import Foundation

// PropertySearchStore — fuente de verdad para filtros de búsqueda de propiedades.
// Inyectado via .environment() desde MaresmeApp para persistir filtros entre navegaciones.
// Para búsquedas rápidas desde HomeView se usa una instancia local, no el store global.
@Observable
final class PropertySearchStore {
    var filters = PropertySearchFilters()

    var hasActiveFilters: Bool { !filters.isEmpty }
    var activeCount:      Int  { filters.activeFilterCount }

    init(initial: PropertySearchFilters = PropertySearchFilters()) {
        self.filters = initial
    }

    func apply(_ newFilters: PropertySearchFilters) {
        filters = newFilters
    }

    func reset() {
        filters = PropertySearchFilters()
    }
}
