param (
    [string]$ProjectRef
)

if (-not $ProjectRef) {
    Write-Host "Kullanım: .\scripts\deploy_edge_function.ps1 -ProjectRef SİZİN_PROJE_REF_ID" -ForegroundColor Yellow
    Write-Host "Örnek: .\scripts\deploy_edge_function.ps1 -ProjectRef xyzcompany" -ForegroundColor Cyan
    exit
}

Write-Host "Supabase Edge Function ('get-stream-metadata') dağıtılıyor..." -ForegroundColor Green
npx supabase functions deploy get-stream-metadata --project-ref $ProjectRef --no-verify-jwt
