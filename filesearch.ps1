function filesearch()
{

Get-ChildItem -Path "C:\" -Recurse -File -ErrorAction SilentlyContinue |
Where-Object { $_.Length -gt 1GB } |
Select-Object FullName, Length |
Sort-Object Length -Descending


}

filesearch