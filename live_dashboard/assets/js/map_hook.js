import maplibregl from "maplibre-gl"
import "maplibre-gl/dist/maplibre-gl.css"

export const MapHook = {
  mounted() {
    const mapContainer = this.el

    this.map = new maplibregl.Map({
      container: mapContainer,
      style: {
        version: 8,
        sources: {
          "osm-tiles": {
            type: "raster",
            tiles: [
              "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
            ],
            tileSize: 256,
            attribution: "© OpenStreetMap contributors"
          }
        },
        layers: [
          {
            id: "osm-tiles-layer",
            type: "raster",
            source: "osm-tiles",
            minzoom: 0,
            maxzoom: 22
          }
        ]
      },
      center: [15.5, 49.8],
      zoom: 6.5
    })

    this.defaultCenter = [15.5, 49.8]
    this.defaultZoom = 6.5

    this.handleEvent("reset-map", () => {
      this.resetMap()
    })
  },

  updated() {
    this.handleEvent("reset-map", () => {
      this.resetMap()
    })
  },

  resetMap() {
    if (this.map) {
      this.map.flyTo({
        center: this.defaultCenter,
        zoom: this.defaultZoom,
        duration: 1000
      })
    }
  },

  destroyed() {
    if (this.map) {
      this.map.remove()
    }
  }
}

