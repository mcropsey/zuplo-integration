#!/bin/bash
# =============================================================================
# crAPI API Tests via Zuplo Gateway
# Gateway: https://crapi-cropseyit-com-main-64db34b.zuplo.app
# =============================================================================

ZUPLO="https://crapi-cropseyit-com-main-64db34b.zuplo.app"
EMAIL="mike1@my.lab"
PASSWORD="Mylab123!"

# After login, copy the token from the response and set it here:
TOKEN="PASTE_YOUR_JWT_TOKEN_HERE"

echo "========================================"
echo " crAPI Tests via Zuplo Gateway"
echo "========================================"

# =============================================================================
# PART 1: AUTH - No token required
# =============================================================================

echo ""
echo "--- 1. SIGN UP (create a new user) ---"
curl -s -X POST "$ZUPLO/identity/api/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser1@my.lab",
    "name": "Test User",
    "number": "5551234567",
    "password": "Mylab123!"
  }' | python3 -m json.tool

echo ""
echo "--- 2. LOGIN ---"
curl -s -X POST "$ZUPLO/identity/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" | python3 -m json.tool

# NOTE: Copy the token from the login response above and set TOKEN= at the top

echo ""
echo "--- 3. FORGOT PASSWORD (sends OTP to MailHog) ---"
curl -s -X POST "$ZUPLO/identity/api/auth/forget-password" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\"}" | python3 -m json.tool

# =============================================================================
# PART 2: USER - Token required
# =============================================================================

echo ""
echo "--- 4. GET USER DASHBOARD ---"
curl -s -X GET "$ZUPLO/identity/api/v2/user/dashboard" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

echo ""
echo "--- 5. RESET PASSWORD ---"
curl -s -X POST "$ZUPLO/identity/api/v2/user/reset-password" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"Mylab123!\"}" | python3 -m json.tool

# =============================================================================
# PART 3: VEHICLES
# =============================================================================

echo ""
echo "--- 6. GET USER VEHICLES ---"
curl -s -X GET "$ZUPLO/identity/api/v2/vehicle/vehicles" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

# NOTE: Copy a vehicleId UUID from the vehicles response for the next command
VEHICLE_ID="PASTE_VEHICLE_UUID_HERE"

echo ""
echo "--- 7. GET VEHICLE LOCATION ---"
curl -s -X GET "$ZUPLO/identity/api/v2/vehicle/$VEHICLE_ID/location" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

echo ""
echo "--- 8. RESEND VEHICLE DETAILS EMAIL ---"
curl -s -X POST "$ZUPLO/identity/api/v2/vehicle/resend_email" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

# =============================================================================
# PART 4: COMMUNITY / FORUM POSTS
# =============================================================================

echo ""
echo "--- 9. GET RECENT POSTS ---"
curl -s -X GET "$ZUPLO/community/api/v2/community/posts/recent?limit=5&offset=0" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

echo ""
echo "--- 10. CREATE A POST ---"
curl -s -X POST "$ZUPLO/community/api/v2/community/posts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test post via Zuplo",
    "content": "This API call went through the Zuplo gateway!"
  }' | python3 -m json.tool

# NOTE: Copy a post ID from the recent posts response for the next commands
POST_ID="PASTE_POST_ID_HERE"

echo ""
echo "--- 11. GET A SPECIFIC POST ---"
curl -s -X GET "$ZUPLO/community/api/v2/community/posts/$POST_ID" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

echo ""
echo "--- 12. ADD A COMMENT TO A POST ---"
curl -s -X POST "$ZUPLO/community/api/v2/community/posts/$POST_ID/comment" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content": "Comment via Zuplo gateway"}' | python3 -m json.tool

# =============================================================================
# PART 5: SHOP
# =============================================================================

echo ""
echo "--- 13. GET PRODUCTS ---"
curl -s -X GET "$ZUPLO/workshop/api/shop/products" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

echo ""
echo "--- 14. CREATE AN ORDER ---"
curl -s -X POST "$ZUPLO/workshop/api/shop/orders" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"product_id": 1, "quantity": 1}' | python3 -m json.tool

echo ""
echo "--- 15. GET ALL ORDERS ---"
curl -s -X GET "$ZUPLO/workshop/api/shop/orders/all?limit=10&offset=0" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

# NOTE: Copy an order ID from the orders response
ORDER_ID="PASTE_ORDER_ID_HERE"

echo ""
echo "--- 16. GET ORDER BY ID ---"
curl -s -X GET "$ZUPLO/workshop/api/shop/orders/$ORDER_ID" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

echo ""
echo "--- 17. APPLY COUPON ---"
curl -s -X POST "$ZUPLO/workshop/api/shop/apply_coupon" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"coupon_code": "TRAC075", "amount": 75}' | python3 -m json.tool

# =============================================================================
# PART 6: MECHANICS / WORKSHOP
# =============================================================================

echo ""
echo "--- 18. GET MECHANICS ---"
curl -s -X GET "$ZUPLO/workshop/api/mechanic/" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

echo ""
echo "--- 19. MECHANIC SIGNUP ---"
curl -s -X POST "$ZUPLO/workshop/api/mechanic/signup" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Mechanic",
    "email": "testmech1@my.lab",
    "number": "5559876543",
    "password": "Mylab123!",
    "mechanic_code": "TRAC_TEST1"
  }' | python3 -m json.tool

# =============================================================================
# PART 7: COUPON (Community service)
# =============================================================================

echo ""
echo "--- 20. VALIDATE COUPON ---"
curl -s -X POST "$ZUPLO/community/api/v2/coupon/validate-coupon" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"coupon_code": "TRAC075"}' | python3 -m json.tool

# =============================================================================
# PART 8: GATEWAY PROTECTION TESTS
# =============================================================================

echo ""
echo "========================================"
echo " Gateway Protection Tests"
echo "========================================"

echo ""
echo "--- 21. TEST INVALID ENDPOINT (should return 404 from Zuplo) ---"
curl -s -i "$ZUPLO/identity/api/some-fake-endpoint"

echo ""
echo "--- 22. RATE LIMIT TEST (send 15 requests, 11+ should return 429) ---"
echo "Sending 15 login requests..."
for i in {1..15}; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$ZUPLO/identity/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
  echo "Request $i: HTTP $STATUS"
done

echo ""
echo "========================================"
echo " Done. Check Zuplo Logs at:"
echo " portal.zuplo.com > crapi-cropseyit-com > Logs"
echo "========================================"
