#Mass Delete Canvas Courses

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer #############PUT TOKEN HERE#######################")
$headers.Add("Cookie", "_csrf_token=7%2BAgYQOPldrqHGaNLBivMv%2B2prmmd0n98XZbIwBKMDWOqW05RcHU6pMuCtdtKsphq93i%2F%2B5PH5KIL3RmVytGZw%3D%3D; _legacy_normandy_session=leKa6BapbjEaDfiUNos5Zg.PavLYvvmI10MDEBA1zVUHRtWj23d_ruFe4Uq8MOkLmRBZPu5EoeR_ksfK5ERYOpJV-7X_mfAyaodr6kjjZuOuK-yPaknWTdtOhyL-_7FW24twWglzXdDm5HquhvN-Yqf.vRBCYVqv2RWNIszu6LsJlRYXwQo.Y1_KnQ; canvas_session=leKa6BapbjEaDfiUNos5Zg.PavLYvvmI10MDEBA1zVUHRtWj23d_ruFe4Uq8MOkLmRBZPu5EoeR_ksfK5ERYOpJV-7X_mfAyaodr6kjjZuOuK-yPaknWTdtOhyL-_7FW24twWglzXdDm5HquhvN-Yqf.vRBCYVqv2RWNIszu6LsJlRYXwQo.Y1_KnQ; log_session_id=722e87b71ad5e5ec1039b48a7cc926d4")

$courses = "13619,13620,13621,13622,13623,13624,13627,13628,13629,13630,13631,13632,13633,13634,13635,13636,13637,13638,13639,13640,13643,13644,13645,13646,13647,13648,13649,13650,13651,13652,13679,13680,13681,13682,13683,13684,13685,13686,13687,13688,13689,13692,13693,13711,13712,13740"

$courses1 = $courses.Split(",")

foreach ($item in $courses1) {
    $multipartContent = [System.Net.Http.MultipartFormDataContent]::new()
$stringHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new("form-data")
$stringHeader.Name = "event"
$stringContent = [System.Net.Http.StringContent]::new("delete")
$stringContent.Headers.ContentDisposition = $stringHeader
$multipartContent.Add($stringContent)

$body = $multipartContent
    $url = ("https://marshfield.instructure.com/api/v1/courses/" + $item)
    $response = Invoke-WebRequest $url -Method 'DELETE' -Headers $headers -Body $body
}
