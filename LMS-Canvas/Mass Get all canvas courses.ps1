#Mass Get all canvas courses
#Only Gets Non Deleted Courses

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer #############PUT TOKEN HERE#######################")
$headers.Add("Cookie", "_csrf_token=7%2BAgYQOPldrqHGaNLBivMv%2B2prmmd0n98XZbIwBKMDWOqW05RcHU6pMuCtdtKsphq93i%2F%2B5PH5KIL3RmVytGZw%3D%3D; _legacy_normandy_session=leKa6BapbjEaDfiUNos5Zg.PavLYvvmI10MDEBA1zVUHRtWj23d_ruFe4Uq8MOkLmRBZPu5EoeR_ksfK5ERYOpJV-7X_mfAyaodr6kjjZuOuK-yPaknWTdtOhyL-_7FW24twWglzXdDm5HquhvN-Yqf.vRBCYVqv2RWNIszu6LsJlRYXwQo.Y1_KnQ; canvas_session=leKa6BapbjEaDfiUNos5Zg.PavLYvvmI10MDEBA1zVUHRtWj23d_ruFe4Uq8MOkLmRBZPu5EoeR_ksfK5ERYOpJV-7X_mfAyaodr6kjjZuOuK-yPaknWTdtOhyL-_7FW24twWglzXdDm5HquhvN-Yqf.vRBCYVqv2RWNIszu6LsJlRYXwQo.Y1_KnQ; log_session_id=722e87b71ad5e5ec1039b48a7cc926d4")

$response = Invoke-WebRequest "https://marshfield.instructure.com/api/v1/accounts/1/courses?page=1&per_page=100" -Method 'GET' -Headers $headers

$courses = $response.content | ConvertFrom-Json

$response.RelationLink.next

while ($response.RelationLink.next){
    $response = Invoke-WebRequest $response.RelationLink.next -Method 'GET' -Headers $headers
    $courses += $response.content | ConvertFrom-Json
}

$courses | Export-CSV -NoTypeInformation -UseQuotes Always -Path "C:\temp\Courses.csv" -Force
