# HN Validation System - Integration Guide

## Files Created

1. **public/js/hn-validation.js** - Client-side validation logic
2. **views/partials/patient-hn-validation-section.ejs** - UI components
3. **routes/hn-validation-api.js** - Backend API endpoints
4. **database/migrations/add_hn_validation.sql** - Database migration

## Integration Steps

### Step 1: Run Database Migration

```bash
mysql -u your_username -p your_database < database/migrations/add_hn_validation.sql
```

Or run the SQL file in your MySQL client.

### Step 2: Update app.js

Add these lines to `app.js`:

```javascript
// At the top with other requires
const hnValidation = require('./routes/hn-validation-api');

// After database connection is established (after `const db = mysql.createConnection(...)`)
// Setup HN validation routes
hnValidation.setupHNValidationRoutes(app, db, authenticateToken);

// Also update the POST /api/patients endpoint to include additional validation
```

### Step 3: Update POST /api/patients endpoint in app.js

Replace or modify the existing `POST /api/patients` endpoint with enhanced validation:

```javascript
app.post('/api/patients', authenticateToken, [
    body('hn').notEmpty().matches(/^PT\d{6}$/).withMessage('Invalid HN format'),
    body('idType').isIn(['thai_id', 'passport']).withMessage('Invalid ID type'),
    body('idValue').notEmpty().withMessage('ID value is required'),
    body('first_name').notEmpty(),
    body('last_name').notEmpty(),
    body('dob').isDate(),
    body('diagnosis').notEmpty()
], async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { hn, idType, idValue, ...otherFields } = req.body;

    try {
        // SERVER-SIDE RE-VALIDATION
        if (idType === 'thai_id') {
            if (!hnValidation.validateThaiNationalID(idValue)) {
                return res.status(400).json({
                    success: false,
                    message: 'Invalid Thai National ID checksum.'
                });
            }
        } else if (idType === 'passport') {
            if (!hnValidation.validatePassportID(idValue)) {
                return res.status(400).json({
                    success: false,
                    message: 'Invalid passport format.'
                });
            }
        }

        // Verify HN year matches current year
        const currentYear = moment().format('YY');
        const hnYear = hn.substring(2, 4);
        if (hnYear !== currentYear) {
            return res.status(400).json({
                success: false,
                message: `Invalid HN year. Expected PT${currentYear}XXXX`
            });
        }

        // Check for duplicate ID (race condition prevention)
        const checkQuery = idType === 'thai_id'
            ? 'SELECT id FROM patients WHERE pid = ? LIMIT 1'
            : 'SELECT id FROM patients WHERE passport_no = ? LIMIT 1';

        db.query(checkQuery, [idValue], (err, duplicateCheck) => {
            if (err) {
                return res.status(500).json({ success: false, message: 'Database error' });
            }

            if (duplicateCheck.length > 0) {
                return res.status(409).json({
                    success: false,
                    message: 'This ID is already registered. Please verify again.'
                });
            }

            // Generate PT Number
            const pt_number = generatePTNumber();

            // Prepare patient data
            const patientData = {
                hn: hn,
                pt_number: pt_number,
                pid: idType === 'thai_id' ? idValue : null,
                passport_no: idType === 'passport' ? idValue : null,
                created_by: req.user.userId,
                ...otherFields
            };

            // Insert patient
            db.query('INSERT INTO patients SET ?', patientData, (err, result) => {
                if (err) {
                    if (err.code === 'ER_DUP_ENTRY') {
                        return res.status(409).json({
                            success: false,
                            message: 'HN already exists. Please verify ID again.'
                        });
                    }
                    return res.status(500).json({ success: false, message: 'Failed to create patient' });
                }

                res.status(201).json({
                    success: true,
                    message: 'Patient created successfully',
                    patient: { id: result.insertId, hn, pt_number }
                });
            });
        });

    } catch (error) {
        console.error('Create patient error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});
```

### Step 4: Update patient-register.ejs

Replace the existing "Patient Identifiers" card section with:

```ejs
<%- include('partials/patient-hn-validation-section') %>
```

Or manually copy the content from `views/partials/patient-hn-validation-section.ejs` into the appropriate location.

**Important**: Remove or comment out the old HN, Thai ID, and Passport input fields to avoid conflicts.

### Step 5: Ensure Bootstrap Icons are loaded

Make sure your patient-register.ejs includes Bootstrap Icons:

```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css">
```

## Testing Checklist

- [ ] Database migration completed successfully
- [ ] API endpoint `/api/patients/check-id` returns expected responses
- [ ] Thai ID validation works (checksum validation)
- [ ] Passport validation works (format validation)
- [ ] PTHN generation increments correctly
- [ ] Duplicate detection shows existing patient info
- [ ] Form submission blocked without ID verification
- [ ] Race condition handling prevents duplicate creation
- [ ] "View Patient Details" button works
- [ ] "Create PN Case" redirect works (if PN module exists)

## API Endpoints

### POST /api/patients/check-id
Check if ID exists and get next PTHN

**Request:**
```json
{
  "idType": "thai_id",
  "idValue": "1234567890123"
}
```

**Response (Available):**
```json
{
  "success": true,
  "isDuplicate": false,
  "nextPTHN": "PT250001"
}
```

**Response (Duplicate):**
```json
{
  "success": true,
  "isDuplicate": true,
  "patient": { "id": 1, "hn": "PT250001", ... }
}
```

### GET /api/admin/pthn-stats
Get PTHN generation statistics (Admin only)

**Response:**
```json
{
  "success": true,
  "stats": [
    {
      "year": 25,
      "last_sequence": 42,
      "last_pthn": "PT250042",
      "next_pthn": "PT250043",
      "remaining": 9957
    }
  ]
}
```

## PTHN Format

- **Format**: PTYYXXXX
- **Example**: PT250001
  - PT = Prefix
  - 25 = Year (2025)
  - 0001 = Sequence number
- **Auto-resets** to 0001 every new year

## Troubleshooting

### Error: "Table 'pthn_sequence' doesn't exist"
- Run the database migration: `database/migrations/add_hn_validation.sql`

### Error: "Cannot find module './routes/hn-validation-api'"
- Ensure `routes/hn-validation-api.js` exists
- Check the path in your `require()` statement

### Error: "Duplicate entry for key 'unique_hn'"
- This is expected behavior (prevents duplicates)
- User should verify ID again to get a new PTHN

### UI not showing verification alerts
- Check browser console for JavaScript errors
- Ensure `public/js/hn-validation.js` is loaded
- Verify template elements exist in the HTML

## Support

For issues or questions, refer to the complete design documentation in the `/design/` directory.
