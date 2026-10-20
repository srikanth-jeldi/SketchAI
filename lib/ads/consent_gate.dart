/// Do not initialize advertising until all privacy steps allow requests.
Future<bool> prepareAdConsent({
  required Future<bool> Function() update,
  required Future<bool> Function() showIfRequired,
  required Future<bool> Function() canRequestAds,
}) async {
  try {
    if (!await update()) return false;
    if (!await showIfRequired()) return false;
    return await canRequestAds();
  } catch (_) {
    return false;
  }
}
