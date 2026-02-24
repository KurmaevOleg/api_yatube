Write-Host "=== API TEST START ==="

$BASE_URL = "http://127.0.0.1:8000/api/v1"

# CONFIG: usernames/passwords must exist in DB
$USERNAME1 = "user1"
$PASSWORD1 = "pass1234"

$USERNAME2 = "user2"
$PASSWORD2 = "pass1234"

function Get-Token($username, $password) {
    $body = @{
        username = $username
        password = $password
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Method Post -Uri "$BASE_URL/api-token-auth/" -ContentType "application/json" -Body $body
        return $response.token
    } catch {
        Write-Host "ERROR: failed to get token for $username" -ForegroundColor Red
        return $null
    }
}

Write-Host ""
Write-Host "Getting tokens..."
$TOKEN1 = Get-Token $USERNAME1 $PASSWORD1
$TOKEN2 = Get-Token $USERNAME2 $PASSWORD2

if (-not $TOKEN1) { Write-Host "Cannot get token for user1. Create user1 first." -ForegroundColor Red; exit 1 }
if (-not $TOKEN2) { Write-Host "Cannot get token for user2. Create user2 first." -ForegroundColor Red; exit 1 }

Write-Host "Tokens OK."

$HEADERS1 = @{ Authorization = "Token $TOKEN1" }
$HEADERS2 = @{ Authorization = "Token $TOKEN2" }

# Create post
Write-Host "`nCreating a post..."
$postBody = @{ text = "PowerShell test post" } | ConvertTo-Json
try {
    $post = Invoke-RestMethod -Method Post -Uri "$BASE_URL/posts/" -Headers $HEADERS1 -ContentType "application/json" -Body $postBody
} catch {
    Write-Host "ERROR: creating post failed." -ForegroundColor Red
    exit 1
}

$postId = $post.id
if ($postId) { Write-Host "Post created id=$postId" } else { Write-Host "Post creation returned no id" -ForegroundColor Red; exit 1 }

# Get list
Write-Host "`nGetting posts list..."
$posts = Invoke-RestMethod -Method Get -Uri "$BASE_URL/posts/" -Headers $HEADERS1
Write-Host ("Posts returned: {0}" -f ($posts | Measure-Object).Count)

# Update own post
Write-Host "`nUpdating own post..."
$updateBody = @{ text = "Updated text by owner" } | ConvertTo-Json
$updated = Invoke-RestMethod -Method Patch -Uri "$BASE_URL/posts/$postId/" -Headers $HEADERS1 -ContentType "application/json" -Body $updateBody
if ($updated.text -eq "Updated text by owner") { Write-Host "Update OK" } else { Write-Host "Update did not persist" -ForegroundColor Yellow }

# Forbidden test: other user attempts update (expect 403)
Write-Host "`nTesting Forbidden (other user update)..."
$forbidden = $false
try {
    Invoke-RestMethod -Method Patch -Uri "$BASE_URL/posts/$postId/" -Headers $HEADERS2 -ContentType "application/json" -Body $updateBody -ErrorAction Stop
    Write-Host "ERROR: other user was able to update the post (should be 403)" -ForegroundColor Red
} catch {
    if ($_.Exception.Response -and $_.Exception.Response.StatusCode.Value__ -eq 403) {
        Write-Host "403 Forbidden as expected"
        $forbidden = $true
    } else {
        Write-Host "Unexpected error during forbidden test: $_" -ForegroundColor Yellow
    }
}

# Create comment
Write-Host "`nCreating a comment..."
$commentBody = @{ text = "Test comment" } | ConvertTo-Json
$comment = Invoke-RestMethod -Method Post -Uri "$BASE_URL/posts/$postId/comments/" -Headers $HEADERS1 -ContentType "application/json" -Body $commentBody
$commentId = $comment.id
if ($commentId) { Write-Host "Comment created id=$commentId" } else { Write-Host "Comment creation failed" -ForegroundColor Red; exit 1 }

# Delete comment
Write-Host "`nDeleting comment..."
Invoke-RestMethod -Method Delete -Uri "$BASE_URL/posts/$postId/comments/$commentId/" -Headers $HEADERS1
Write-Host "Comment deleted."

# Delete post
Write-Host "`nDeleting post..."
Invoke-RestMethod -Method Delete -Uri "$BASE_URL/posts/$postId/" -Headers $HEADERS1
Write-Host "Post deleted."

Write-Host "`n=== TESTS FINISHED ===" -ForegroundColor Green
