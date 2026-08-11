// CloudFront viewer-request function. The site origin is the S3 REST API
// via OAC (not an S3 website endpoint), so CloudFront never appends
// index.html to directory-style requests on its own - only true root "/"
// gets that treatment, via default_root_object. Every other extensionless
// path (e.g. /members/, /labs/foo/) would otherwise be requested from S3
// literally, miss, and come back as 403 AccessDenied (the OAC principal
// lacks s3:ListBucket, so S3 can't return a plain 404 for a missing key).
function handler(event) {
    var request = event.request;
    var uri = request.uri;

    if (uri.endsWith('/')) {
        request.uri += 'index.html';
    } else if (!uri.includes('.')) {
        request.uri += '/index.html';
    }

    return request;
}
