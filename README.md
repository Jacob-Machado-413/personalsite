# jacobmachado.com /  phyllistine.com


My personal site — [jacobmachado.com](https://jacobmachado.com). Flutter for the
web, because a static page seemed boring. It's an underwater scene: a school of
fish that scatter from your cursor, and a red one you follow to the portfolio.

Every fish is drawn with `Canvas` paths — no sprites — animated off a tail-wag
phase driving both the bend and a pulsed thrust, so they swim rather than slide.
Three GLSL shaders sit in `shaders/`: `water.frag` paints the caustics,
`underwater.frag` post-processes the scene (blur, vignette, chromatic
aberration), `kuwahara.frag` was what i wanted to do but was too heavy on browser performance. 
Constants top `lib/home_page.dart`.

```bash
flutter pub get
flutter run -d chrome
```

Production is a two-stage container — `flutter build web --release --wasm`
handed to nginx (`nginx.conf` has the SPA fallback):

```bash
docker build -t site . && docker run -p 8080:80 site
```

Web is the only platform here; the rest is gitignored.
