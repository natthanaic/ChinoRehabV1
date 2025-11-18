/**
 * HN Creation & Validation - Client-Side JavaScript
 * Handles ID verification, PTHN preview, and form validation
 */

// Global State
const HNValidationState = {
    idType: null,
    idValue: null,
    isVerified: false,
    isDuplicate: false,
    previewPTHN: null,
    existingPatient: null
};

// DOM Elements
const elements = {
    idType: document.getElementById('idType'),
    idValue: document.getElementById('idValue'),
    idValueLabel: document.getElementById('idValueLabel'),
    idHelperText: document.getElementById('idHelperText'),
    idErrorText: document.getElementById('idErrorText'),
    btnCheckID: document.getElementById('btnCheckID'),
    hn: document.getElementById('hn'),
    pid: document.getElementById('pid'),
    passport: document.getElementById('passport'),
    verificationSection: document.getElementById('verificationSection'),
    verificationAlert: document.getElementById('verificationAlert'),
    templateIdAvailable: document.getElementById('templateIdAvailable'),
    templateIdExists: document.getElementById('templateIdExists'),
    templateVerificationError: document.getElementById('templateVerificationError'),
    patientForm: document.getElementById('patientForm')
};

// Validation Functions
function validateThaiNationalID(id) {
    id = id.replace(/[\s-]/g, '');
    if (!/^\d{13}$/.test(id)) return false;

    let sum = 0;
    for (let i = 0; i < 12; i++) {
        sum += parseInt(id[i]) * (13 - i);
    }
    const checksum = (11 - (sum % 11)) % 10;
    return checksum === parseInt(id[12]);
}

function validatePassportID(passport) {
    passport = passport.replace(/\s/g, '');
    return /^[A-Z0-9]{6,20}$/i.test(passport);
}

function formatThaiID(id) {
    id = id.replace(/[\s-]/g, '');
    if (id.length === 13) {
        return `${id.substring(0, 1)}-${id.substring(1, 5)}-${id.substring(5, 10)}-${id.substring(10, 12)}-${id.substring(12, 13)}`;
    }
    return id;
}

// Event Handlers
elements.idType.addEventListener('change', function() {
    const selectedType = this.value;
    HNValidationState.idType = selectedType;

    elements.idValue.value = '';
    elements.hn.value = '';
    resetVerificationState();

    if (selectedType === 'thai_id') {
        elements.idValueLabel.textContent = 'Thai National ID';
        elements.idValue.placeholder = '1234567890123';
        elements.idValue.maxLength = 13;
        elements.idHelperText.textContent = '13-digit Thai National ID';
        elements.btnCheckID.disabled = false;
    } else if (selectedType === 'passport') {
        elements.idValueLabel.textContent = 'Passport Number';
        elements.idValue.placeholder = 'AB1234567';
        elements.idValue.maxLength = 20;
        elements.idHelperText.textContent = '6-20 alphanumeric characters';
        elements.btnCheckID.disabled = false;
    } else {
        elements.idValueLabel.textContent = 'ID Number';
        elements.idValue.placeholder = 'Enter ID number';
        elements.idHelperText.textContent = 'Select ID type first';
        elements.btnCheckID.disabled = true;
    }

    if (selectedType) {
        elements.idValue.focus();
    }
});

elements.idValue.addEventListener('input', function() {
    const value = this.value.trim();
    HNValidationState.idValue = value;
    resetVerificationState();

    if (HNValidationState.idType === 'thai_id') {
        elements.btnCheckID.disabled = value.length !== 13;
    } else if (HNValidationState.idType === 'passport') {
        elements.btnCheckID.disabled = value.length < 6;
    }
});

elements.idValue.addEventListener('blur', function() {
    const value = this.value.trim();
    if (!value) return;

    let isValid = false;
    let errorMessage = '';

    if (HNValidationState.idType === 'thai_id') {
        isValid = validateThaiNationalID(value);
        errorMessage = 'Invalid Thai National ID. Please check the checksum.';
        if (isValid) {
            HNValidationState.idValue = value;
        }
    } else if (HNValidationState.idType === 'passport') {
        isValid = validatePassportID(value);
        errorMessage = 'Invalid passport format. Use 6-20 alphanumeric characters.';
    }

    if (value && !isValid) {
        elements.idValue.classList.add('is-invalid');
        elements.idErrorText.textContent = errorMessage;
        elements.btnCheckID.disabled = true;
    } else {
        elements.idValue.classList.remove('is-invalid');
        elements.idErrorText.textContent = '';
        elements.btnCheckID.disabled = false;
    }
});

elements.btnCheckID.addEventListener('click', async function() {
    const idType = HNValidationState.idType;
    const idValue = HNValidationState.idValue;

    if (!idType || !idValue) {
        alert('Please select ID type and enter ID number.');
        return;
    }

    const originalText = this.innerHTML;
    this.disabled = true;
    this.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span> Checking...';

    try {
        const result = await checkIDDuplication(idType, idValue);

        if (result.isDuplicate) {
            showDuplicateAlert(result.patient);
        } else {
            showAvailableAlert(result.nextPTHN);
        }
    } catch (error) {
        console.error('ID verification error:', error);
        showErrorAlert(error.message || 'Unable to verify ID. Please try again.');
    } finally {
        this.disabled = false;
        this.innerHTML = originalText;
    }
});

// API Functions
async function checkIDDuplication(idType, idValue) {
    const response = await fetch('/api/patients/check-id', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${localStorage.getItem('token')}`
        },
        body: JSON.stringify({ idType, idValue })
    });

    if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || 'API request failed');
    }

    return await response.json();
}

// UI Update Functions
function showAvailableAlert(nextPTHN) {
    HNValidationState.isVerified = true;
    HNValidationState.isDuplicate = false;
    HNValidationState.previewPTHN = nextPTHN;

    const template = elements.templateIdAvailable;
    const content = template.content.cloneNode(true);
    content.getElementById('previewPTHN').textContent = nextPTHN;

    elements.verificationAlert.innerHTML = '';
    elements.verificationAlert.appendChild(content);
    elements.verificationSection.style.display = 'block';

    elements.hn.value = nextPTHN;

    if (HNValidationState.idType === 'thai_id') {
        elements.pid.value = HNValidationState.idValue;
        elements.passport.value = '';
    } else if (HNValidationState.idType === 'passport') {
        elements.passport.value = HNValidationState.idValue;
        elements.pid.value = '';
    }

    elements.verificationSection.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    updateWorkflowStep(2);
}

function showDuplicateAlert(patient) {
    HNValidationState.isVerified = false;
    HNValidationState.isDuplicate = true;
    HNValidationState.existingPatient = patient;

    const template = elements.templateIdExists;
    const content = template.content.cloneNode(true);

    content.getElementById('existingHN').textContent = patient.hn;
    content.getElementById('existingPT').textContent = patient.pt_number;
    content.getElementById('existingName').textContent = `${patient.title || ''} ${patient.first_name} ${patient.last_name}`.trim();
    content.getElementById('existingDOB').textContent = formatDate(patient.dob);
    content.getElementById('existingClinic').textContent = patient.clinic_name || 'N/A';
    content.getElementById('existingDate').textContent = formatDate(patient.created_at);

    const btnViewPatient = content.getElementById('btnViewPatient');
    const btnCreatePN = content.getElementById('btnCreatePN');

    btnViewPatient.addEventListener('click', () => handleViewPatient(patient.id));
    btnCreatePN.addEventListener('click', () => handleCreatePN(patient.id, patient.hn));

    elements.verificationAlert.innerHTML = '';
    elements.verificationAlert.appendChild(content);
    elements.verificationSection.style.display = 'block';

    elements.hn.value = '';
    elements.verificationSection.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

function showErrorAlert(errorMessage) {
    const template = elements.templateVerificationError;
    const content = template.content.cloneNode(true);
    content.getElementById('errorMessage').textContent = errorMessage;

    elements.verificationAlert.innerHTML = '';
    elements.verificationAlert.appendChild(content);
    elements.verificationSection.style.display = 'block';

    resetVerificationState();
}

function resetVerificationState() {
    HNValidationState.isVerified = false;
    HNValidationState.isDuplicate = false;
    HNValidationState.previewPTHN = null;
    HNValidationState.existingPatient = null;

    elements.verificationSection.style.display = 'none';
    elements.verificationAlert.innerHTML = '';
    elements.hn.value = '';

    updateWorkflowStep(1);
}

function handleViewPatient(patientId) {
    window.open(`/patients/${patientId}`, '_blank');
}

function handleCreatePN(patientId, patientHN) {
    if (confirm(`Create a new PN (Patient Number) case for patient ${patientHN}?\n\nThis will redirect you to the PN creation page.`)) {
        window.location.href = `/pn/create?patient_id=${patientId}&hn=${patientHN}`;
    }
}

function updateWorkflowStep(step) {
    const step1 = document.getElementById('step1');
    const step2 = document.getElementById('step2');
    const step3 = document.getElementById('step3');

    if (!step1 || !step2 || !step3) return;

    [step1, step2, step3].forEach(el => {
        el.querySelector('.badge').classList.remove('bg-primary');
        el.querySelector('.badge').classList.add('bg-secondary');
        el.querySelector('small').classList.add('text-muted');
    });

    const steps = [step1, step2, step3];
    for (let i = 0; i < step; i++) {
        steps[i].querySelector('.badge').classList.remove('bg-secondary');
        steps[i].querySelector('.badge').classList.add('bg-primary');
        steps[i].querySelector('small').classList.remove('text-muted');
    }
}

function formatDate(dateStr) {
    if (!dateStr) return 'N/A';
    const date = new Date(dateStr);
    if (isNaN(date.getTime())) return dateStr;

    const day = String(date.getDate()).padStart(2, '0');
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const year = date.getFullYear();
    return `${day}/${month}/${year}`;
}

// Form Submission Validation
elements.patientForm.addEventListener('submit', function(e) {
    if (!HNValidationState.isVerified) {
        e.preventDefault();
        alert('Please verify the patient ID first by clicking "Check ID" button.');
        elements.btnCheckID.focus();
        return false;
    }

    const hn = elements.hn.value;
    if (!hn || !hn.startsWith('PT')) {
        e.preventDefault();
        alert('Hospital Number (HN) is not generated. Please verify the ID first.');
        return false;
    }

    updateWorkflowStep(3);
});

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    console.log('HN Validation module initialized');
    resetVerificationState();
    updateWorkflowStep(1);
});
