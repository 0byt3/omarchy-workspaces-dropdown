pkgname=nier-workspaces-dropdown
pkgver=1.0.0
pkgrel=2
pkgdesc='Active-workspace dropdown widget for the Omarchy bar'
arch=('any')
url='https://github.com/0byt3/omarchy-workspaces-dropdown'
license=('MIT')
depends=('omarchy>=4.0.6' 'quickshell' 'jq' 'util-linux')
install=nier-workspaces-dropdown.install
source=('nier-workspaces-dropdown-enable' 'nier-workspaces-dropdown.install' 'manifest.json' 'Workspaces.qml' 'Model.js' 'README.md' 'LICENSE')
sha256sums=('ddfb47408ee50715db4f79c41cf8d0205f0ec85fe6a3bfb0d8c7cea3c1af17dd' '1e09931fbc48bb4ed56ba8757431510dc2dc92b95f341bc5775d758895cb89c7' 'e69d9a3899ec16450314f40b6d325db8cc9de1d79eb302c28ee3e7a9764da665' '193ec283ae06bb2ec87e0f612645583e686bba583fe66a49cbf4c47462627fd9' 'ce9908a23e60cbf72fd2f4d7052675c8e364b7b5f8be2241ff792fc8b4c7b5e1' '042d46504d8fde394a269c73d28a2b1a8390d0de49566d281a17dfd53745dce8' '717ba1949502290f8e47688ae2e323acd06c8ca47aec9f7596b15f678c1af4a2')
package() {
  install -Dm755 nier-workspaces-dropdown-enable "$pkgdir/usr/share/nier/bin/nier-workspaces-dropdown-enable"
  install -d "$pkgdir/usr/bin"
  ln -s /usr/share/nier/bin/nier-workspaces-dropdown-enable "$pkgdir/usr/bin/nier-workspaces-dropdown-enable"
  install -d "$pkgdir/usr/share/nier/plugins/nier.workspaces-dropdown"
  install -m644 manifest.json Workspaces.qml Model.js "$pkgdir/usr/share/nier/plugins/nier.workspaces-dropdown/"
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
}
