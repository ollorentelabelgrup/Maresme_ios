import SwiftUI
import MapKit
import CoreLocation

struct PropertyLocationPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let initialAddress: String
    let initialLat: Double?
    let initialLng: Double?
    let onLocationSelected: (Double, Double, String) -> Void

    // Centro por defecto: comarca del Maresme
    private static let defaultCenter = CLLocationCoordinate2D(latitude: 41.5891, longitude: 2.7497)

    @State private var cameraPosition: MapCameraPosition
    @State private var centerCoord:    CLLocationCoordinate2D
    @State private var geocodedAddress: String = ""
    @State private var isGeocoding:    Bool    = false
    @State private var reverseTask:    Task<Void, Never>?

    init(
        initialAddress: String = "",
        initialLat: Double? = nil,
        initialLng: Double? = nil,
        onLocationSelected: @escaping (Double, Double, String) -> Void
    ) {
        self.initialAddress     = initialAddress
        self.initialLat         = initialLat
        self.initialLng         = initialLng
        self.onLocationSelected = onLocationSelected

        let coord: CLLocationCoordinate2D
        if let lat = initialLat, let lng = initialLng {
            coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        } else {
            coord = Self.defaultCenter
        }
        _centerCoord    = State(initialValue: coord)
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: coord,
            span:   MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }

    var body: some View {
        ZStack {
            Map(position: $cameraPosition)
                .ignoresSafeArea()
                .onMapCameraChange(frequency: .onEnd) { ctx in
                    centerCoord = ctx.region.center
                    reverseTask?.cancel()
                    reverseTask = Task { await reverseGeocode() }
                }

            // Pin fijo en el centro de pantalla (el mapa se mueve bajo él)
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 42, weight: .regular))
                .foregroundStyle(Color.maresmeBlue)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: -76)
                .allowsHitTesting(false)

            VStack {
                Spacer()
                bottomPanel
            }
        }
        .navigationTitle("Seleccionar ubicación")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") { dismiss() }
            }
        }
        .task { await forwardGeocodeInitial() }
    }

    // MARK: - Bottom panel

    private var bottomPanel: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(geocodedAddress.isEmpty ? Color.maresmeSubtext : Color.maresmeBlue)

                Text(geocodedAddress.isEmpty
                    ? "Mueve el mapa para seleccionar la ubicación"
                    : geocodedAddress)
                    .font(.callout)
                    .foregroundStyle(geocodedAddress.isEmpty ? Color.maresmeSubtext : Color.maresmeText)
                    .lineLimit(2)

                Spacer()

                if isGeocoding {
                    ProgressView().scaleEffect(0.75)
                }
            }
            .padding(.horizontal, 20)

            Button {
                onLocationSelected(centerCoord.latitude, centerCoord.longitude, geocodedAddress)
                dismiss()
            } label: {
                Text("Confirmar ubicación")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.maresmeBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .padding(.top, 16)
        .background(.ultraThinMaterial)
    }

    // MARK: - Geocoding

    // Forward geocoding: dirección conocida → coordenadas iniciales del mapa
    private func forwardGeocodeInitial() async {
        // Si ya tenemos coordenadas, hacemos reverse para mostrar la dirección
        if initialLat != nil {
            await reverseGeocode()
            return
        }
        guard !initialAddress.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        isGeocoding = true
        defer { isGeocoding = false }

        let query = initialAddress + ", Maresme, España"
        guard let marks = await geocode(address: query),
              let mark  = marks.first,
              let loc   = mark.location else { return }

        centerCoord = loc.coordinate
        cameraPosition = .region(MKCoordinateRegion(
            center: loc.coordinate,
            span:   MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
        geocodedAddress = formatPlacemark(mark)
    }

    // Reverse geocoding: coordenadas del pin → dirección legible
    private func reverseGeocode() async {
        guard !Task.isCancelled else { return }
        isGeocoding = true
        defer { isGeocoding = false }

        let coord    = centerCoord
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        guard let marks = await reverseGeocode(location: location),
              let mark  = marks.first,
              !Task.isCancelled else { return }
        geocodedAddress = formatPlacemark(mark)
    }

    // MARK: - CLGeocoder wrappers (instancia nueva por llamada → sin conflictos de concurrencia)

    private func geocode(address: String) async -> [CLPlacemark]? {
        await withCheckedContinuation { continuation in
            CLGeocoder().geocodeAddressString(address) { marks, _ in
                continuation.resume(returning: marks)
            }
        }
    }

    private func reverseGeocode(location: CLLocation) async -> [CLPlacemark]? {
        await withCheckedContinuation { continuation in
            CLGeocoder().reverseGeocodeLocation(location) { marks, _ in
                continuation.resume(returning: marks)
            }
        }
    }

    // MARK: - Format

    private func formatPlacemark(_ p: CLPlacemark) -> String {
        var parts: [String] = []
        if let street = p.thoroughfare {
            var s = street
            if let num = p.subThoroughfare { s += " \(num)" }
            parts.append(s)
        } else if let name = p.name, !name.isEmpty {
            parts.append(name)
        }
        if let city = p.locality { parts.append(city) }
        return parts.joined(separator: ", ")
    }
}
