# Security Checklist

Comprehensive security checklist based on OWASP Top 10 2025 and industry best practices.

## OWASP Top 10 2025 Mapping

### A01:2025 - Broken Access Control (CRITICAL)

**What to check:**
- Authorization enforced on every endpoint, not just frontend
- RBAC or ABAC properly implemented
- Resource ownership validated (users can only access their own data)
- CORS configuration restricts allowed origins
- Directory traversal prevention
- IDOR (Insecure Direct Object Reference) prevention

**Red flags:**
```python
# BAD: No authorization check
@router.get("/users/{user_id}")
def get_user(user_id: int, db: Session):
    return db.query(User).filter(User.id == user_id).first()

# GOOD: Authorization enforced
@router.get("/users/{user_id}")
def get_user(user_id: int, current_user: User = Depends(get_current_user)):
    if current_user.id != user_id and not current_user.is_admin:
        raise HTTPException(403, "Not authorized")
    return db.query(User).filter(User.id == user_id).first()
```

**Files to examine:**
- Route handlers, controllers
- Middleware files
- Authorization/permission modules
- Database query functions

---

### A02:2025 - Security Misconfiguration (HIGH)

**What to check:**
- Debug mode disabled in production
- Default credentials changed
- Error messages don't leak sensitive info
- Security headers configured
- Unnecessary features disabled
- Cloud/container permissions minimal

**Red flags:**
```python
# BAD: Debug enabled
app = FastAPI(debug=True)

# BAD: Verbose errors
except Exception as e:
    return {"error": str(e), "traceback": traceback.format_exc()}

# BAD: Wildcard CORS
app.add_middleware(CORSMiddleware, allow_origins=["*"])
```

**Required security headers:**
```
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Strict-Transport-Security: max-age=31536000; includeSubDomains
Content-Security-Policy: default-src 'self'
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
```

---

### A03:2025 - Software Supply Chain Failures (HIGH)

**What to check:**
- Dependencies are from trusted sources
- Lock files present (package-lock.json, uv.lock, poetry.lock)
- No vulnerable dependencies (npm audit, pip-audit)
- Dependencies pinned to specific versions
- No hallucinated packages (AI-generated code often imports non-existent packages)

**Red flags:**
```json
// BAD: Unpinned dependencies
"dependencies": {
  "express": "*",
  "lodash": "^4"
}

// GOOD: Pinned versions
"dependencies": {
  "express": "4.18.2",
  "lodash": "4.17.21"
}
```

**Verification commands:**
```bash
# JavaScript/Node.js
npm audit
npx better-npm-audit audit

# Python
pip-audit
safety check

# Check if package exists
npm view <package-name>
pip index versions <package-name>
```

---

### A04:2025 - Cryptographic Failures (HIGH)

**What to check:**
- HTTPS enforced (TLS 1.2+ only)
- Sensitive data encrypted at rest
- Passwords hashed with bcrypt/argon2 (not MD5/SHA1)
- JWT signed with strong algorithm (RS256/ES256 preferred over HS256)
- Secrets not exposed in logs or error messages
- Cryptographic keys rotated

**Red flags:**
```python
# BAD: Weak password hashing
password_hash = hashlib.md5(password.encode()).hexdigest()

# BAD: Insecure JWT
jwt.encode(payload, "secret", algorithm="none")

# BAD: Hardcoded secrets
API_KEY = "sk-live-abc123..."
```

**Secure patterns:**
```python
# GOOD: Strong password hashing
from passlib.context import CryptContext
pwd_context = CryptContext(schemes=["bcrypt"])
password_hash = pwd_context.hash(password)

# GOOD: Secure JWT
jwt.encode(payload, os.environ["JWT_SECRET"], algorithm="RS256")
```

---

### A05:2025 - Injection (CRITICAL)

**Types to check:**
- SQL Injection
- NoSQL Injection
- Command Injection
- LDAP Injection
- XPath Injection
- Template Injection

**Red flags:**
```python
# BAD: SQL Injection
query = f"SELECT * FROM users WHERE id = {user_id}"
cursor.execute(query)

# BAD: Command Injection
os.system(f"convert {user_filename} output.png")

# BAD: Template Injection (Jinja2)
template = Template(user_input)
```

**Secure patterns:**
```python
# GOOD: Parameterized query
cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))

# GOOD: ORM usage
User.query.filter(User.id == user_id).first()

# GOOD: Safe command execution
subprocess.run(["convert", validated_filename, "output.png"], check=True)
```

---

### A06:2025 - Insecure Design (MEDIUM)

**What to check:**
- Threat modeling documentation exists
- Security requirements defined
- Defense in depth (multiple security layers)
- Principle of least privilege applied
- Fail-secure defaults
- Business logic validation

**Red flags:**
- No rate limiting on sensitive operations
- No account lockout after failed attempts
- Missing CAPTCHA on public forms
- No audit logging for sensitive operations
- Trust boundary violations

---

### A07:2025 - Identification and Authentication Failures (CRITICAL)

**What to check:**
- Strong password requirements enforced
- MFA available/required
- Session management secure
- Password reset secure
- Account enumeration prevented
- Brute force protection

**Red flags:**
```python
# BAD: Weak password validation
if len(password) > 3:
    create_user(password)

# BAD: User enumeration
if not user_exists(email):
    return {"error": "User not found"}
else:
    return {"error": "Invalid password"}

# BAD: Insecure session
response.set_cookie("session_id", token)  # Missing security flags
```

**Secure patterns:**
```python
# GOOD: Strong password requirements
password_validator.validate(password)  # Length, complexity, breach check

# GOOD: Constant-time response
return {"error": "Invalid credentials"}  # Same message for both cases

# GOOD: Secure cookies
response.set_cookie(
    "session_id",
    token,
    httponly=True,
    secure=True,
    samesite="strict"
)
```

---

### A08:2025 - Software and Data Integrity Failures (MEDIUM)

**What to check:**
- Code signing or verification
- CI/CD pipeline secured
- Updates from trusted sources
- Deserialization safe
- Database integrity constraints

**Red flags:**
```python
# BAD: Unsafe deserialization
import pickle
data = pickle.loads(user_input)

# BAD: Unsafe YAML loading
import yaml
config = yaml.load(user_input)
```

**Secure patterns:**
```python
# GOOD: Safe deserialization
import json
data = json.loads(user_input)

# GOOD: Safe YAML
config = yaml.safe_load(user_input)
```

---

### A09:2025 - Security Logging and Alerting Failures (MEDIUM)

**What to check:**
- Authentication events logged
- Access control failures logged
- Input validation failures logged
- Logs don't contain sensitive data (passwords, tokens)
- Log integrity protected
- Alerting configured for security events

**Required logging:**
- Login success/failure
- Password changes
- Permission changes
- Admin actions
- Data exports
- API key creation/revocation

**Red flags:**
```python
# BAD: Logging sensitive data
logger.info(f"User login: {email}, password: {password}")

# BAD: No security logging
def admin_delete_user(user_id):
    db.delete(user_id)
    return {"success": True}
```

---

### A10:2025 - Mishandling of Exceptional Conditions (MEDIUM)

**What to check:**
- All exceptions caught and handled
- No fail-open on errors
- Graceful degradation
- Circuit breakers for external services
- Timeout handling
- Resource cleanup in finally blocks

**Red flags:**
```python
# BAD: Fail open
try:
    if not verify_permission(user):
        raise PermissionError()
except:
    pass  # Fails open - allows access on error

# BAD: Swallowed exception
try:
    process_payment(amount)
except Exception:
    pass

# BAD: Leaked stack trace
except Exception as e:
    return {"error": traceback.format_exc()}
```

**Secure patterns:**
```python
# GOOD: Fail closed
try:
    if not verify_permission(user):
        raise PermissionError()
except Exception:
    logger.exception("Permission check failed")
    raise HTTPException(403, "Access denied")

# GOOD: Proper error handling
try:
    process_payment(amount)
except PaymentError as e:
    logger.error(f"Payment failed: {e}")
    raise HTTPException(400, "Payment processing failed")
```

---

## Framework-Specific Security

### Next.js / React

| Check | How to Verify |
|-------|---------------|
| API routes protected | Check `pages/api/` for auth middleware |
| Middleware auth | Check `middleware.ts` for session validation |
| Environment vars | Ensure secrets not prefixed with `NEXT_PUBLIC_` |
| CSP headers | Check `next.config.js` for headers |
| CSRF protection | Verify token validation on mutations |

### FastAPI / Python

| Check | How to Verify |
|-------|---------------|
| Dependencies injected | Routers use `Depends()` for auth |
| Pydantic validation | Request models validate all inputs |
| CORS configured | Check `CORSMiddleware` settings |
| Rate limiting | Check for slowapi or custom limiter |
| JWT validation | Check algorithm and secret management |

### Express / Node.js

| Check | How to Verify |
|-------|---------------|
| Helmet.js enabled | Check for `app.use(helmet())` |
| Body parser limits | Check `express.json({ limit: '1mb' })` |
| Session security | Check cookie settings (httpOnly, secure) |
| Rate limiting | Check for express-rate-limit |
| Input sanitization | Check for express-validator usage |

---

## Severity Classification

**CRITICAL (Fix Immediately):**
- SQL/Command injection vulnerabilities
- Authentication bypass possible
- Hardcoded production credentials
- Unencrypted sensitive data storage

**HIGH (Fix Before Production):**
- Broken access control
- Insufficient input validation
- Missing security headers
- Vulnerable dependencies with known exploits

**MEDIUM (Fix Soon After Launch):**
- Missing rate limiting
- Insufficient logging
- Minor information disclosure
- Non-critical security misconfigurations

**LOW (Address Over Time):**
- Missing optional security headers
- Minor best practice violations
- Informational findings
