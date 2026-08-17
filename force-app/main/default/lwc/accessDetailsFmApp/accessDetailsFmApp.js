import { LightningElement, api, track } from 'lwc';
import getCaseDetails from '@salesforce/apex/SearchControllerFmApp.getCaseDetails';
import saveDetails from '@salesforce/apex/SearchControllerFmApp.saveCaseDetails';
import uploadFileToSite from '@salesforce/apex/FileUploadControllerFmApp.uploadFileToSite';
import saveCheckoutDetails from '@salesforce/apex/SearchControllerFmApp.saveCheckoutDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class ContactDetail extends LightningElement {
    @api caseId ;
    @api permitType;
    @track caseRecord;
    @track isLoading = true;
    @track error;
    @track currentDateTime = ''; // To hold the current date and time
    @track unitNumber = '';
    @track companyName = '';
    @track serviceTypes = '';
    @track tradeCoomercialNumber= '';
    @track vechilePlate= '';
    @track mobileNumber= '';
    @track emiratesId= '';
    @track filesToUpload = [];
    @track uploadedFiles = [];
    @track isUploadDisabled = true;
    @track actionLevel = '';
    @track plateSource = '';
    @track plateNumber = '';
    @track plateCode = '';
    @track isDisabled = true; // Initially disable the buttons
    MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB in bytes
    selectedCountryCode = '+971';  // Default country code
    mobileNumber = '';  // Store mobile number input
    @track timeValue = ''; 
    @track checkouttimeValue='';
    @track isApprove = false; 
    @track isCheckout = true; 
    @track showSearchComponent = false;
    @track isEmiraatesDoc = false;
    @track isVechileDoc = false;
    @track isRejected=false;
    @track showSuccessMessage = false;
    @track errorMessage = '';
    @track isLoading = false; 
    @track showSetion3 = false; 
    @track showSetion2 = false; 
    currentSection = 0; 
    @track showSection1=true;
    @track checkoutDetils=false;
    @track isNextDisabled=false;

    countryCodeOptions = [
        { label: '+971', value: '+971' },
        { label: '+1', value: '+1' },
        { label: '+44', value: '+44' },
        { label: '+91', value: '+91' }
        
    ];
    get isNotCheckin() {
        return this.permitType !== 'checkout';
    }

    connectedCallback() {
        if (this.permitType === 'checkout') {
            this.isCheckout = false;
            this.isApprove = true; 
            this.isRejected=true;
            this.showSetion2 = true; 
            this.checkoutDetils=true;
        }
        this.fetchCaseDetails();
         this.updateCurrentDateTime();
        // Optional: Update the date and time every second (real-time clock)
        setInterval(() => {
            this.updateCurrentDateTime();
        }, 1000);
    }
     fileCategories = [
        { label: 'Emirates ID/Visa', value: 'emiratesIdVisa', required: true },
        { label: 'Vehicle License', value: 'vehicleLicense', required: true },
        { label: 'Company ID', value: 'companyId', required: false },     
        { label: 'Trade License', value: 'tradeLicense', required: false },
    ];

    isRequired(categoryValue) {
        return categoryValue === 'emiratesIdVisa' || categoryValue === 'vehicleLicense';
    }


     updateCurrentDateTime() {
        const now = new Date();
        this.currentDateTime = now.toLocaleString(); // Format as per user locale
    }
     handleFileChange(event) {
        const allowedFormats = ['application/pdf', 'image/png', 'image/jpeg', 'image/jpg']; // MIME types for PDF and JPEG
         const filesformat = event.target.files;
    
    for (let file of filesformat) {
        if (!allowedFormats.includes(file.type)) {
               this.errorMessage = 'Only PDF, PNG, JPG, and JPEG files are allowed.';
            event.target.value = ''; // Clear the file input
            return;
        }
    }
        const files = Array.from(event.target.files);
        const category = event.target.dataset.category;
        const filelabel = event.target.label;
        if (filelabel === 'Emirates ID/Visa') {
            this.isEmiraatesDoc = true;
        }
        if (filelabel === 'Vehicle License') {
            this.isVechileDoc = true;
        }

        if (files.length > 0) {
            for (let file of files) {
                if (file.size > this.MAX_FILE_SIZE) {
                      this.errorMessage='File exceeds the 5MB limit. Please upload a smaller file.';
                 //   this.showToast('Error', `File "${file.name}" exceeds the 5MB limit. Please upload a smaller file.`, 'error');
                    event.target.value = ''; // Clear the input
                    return;
                }
            }

            this.showToast('Success', `File(s) for category ${category} selected successfully.`, 'success');
        }

        files.forEach(file => {
            this.filesToUpload.push({
                file,
                name: file.name,
                category,
                status: 'Pending',
            });
        });

        this.isUploadDisabled = this.filesToUpload.length === 0;
        this.isDisabled=false;
    }
      async uploadFiles() {
       
        const uploadPromises = this.filesToUpload.map(async (fileWrapper) => {
            try {
                const base64Data = await this.readFileAsBase64(fileWrapper.file);
                const result = await uploadFileToSite({
                    fileName: fileWrapper.name,
                    base64Data: base64Data,
                    recordId: this.caseId,
                    category: fileWrapper.category,
                });
                fileWrapper.status = result ? 'Uploaded' : 'Failed';
                this.uploadedFiles.push(fileWrapper);    
            } catch (error) {
                console.error('Error uploading file:', error);
                fileWrapper.status = 'Failed';
            }
        });

        await Promise.all(uploadPromises);

        this.filesToUpload = [];
        this.isUploadDisabled = true;
        this.showSuccessMessage = true; 
        
        //
        //alert('All files have been processed.');
        
    }

    readFileAsBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result.split(',')[1]);
            reader.onerror = reject;
            reader.readAsDataURL(file);
        });
    }
   
    handleInputChange(event) {
        this.isNextDisabled=false;
        const field = event.target.label;
        const val = event.target.dataset.name; 
        if (field === 'Trade License Expiry Date') {
            this.tradeCoomercialNumber = event.target.value;
        }else if (field === 'Vehicle plate details') {
            this.vechilePlate = event.target.value;
        }else if (field === 'Emirates ID') {
            this.emiratesId = event.target.value;
            this.validateEmiratesId(event.target);
        }else if (val === 'mobileNumber') {
         const mobile = event.target.value;
         if (mobile.length !== 9 || isNaN(mobile)) {
          this.errorMessage='Mobile number must be 9 digits';
          return; 
         }
          this.mobileNumber = mobile;
         this.errorMessage = '';
        }

        else if (field === 'Country Code') {
           this.selectedCountryCode = event.target.value;
        }else if (field === 'Plate Code') {
            this.plateCode = event.target.value;
        }else if (field === 'Plate Number') {
            this.plateNumber = event.target.value;
        }else if (field === 'Plate Source') {
            this.plateSource = event.target.value;
        }else if (field === 'checkouttimeValue') {
         this.checkouttimeValue = event.target.value;
        }
    }
   get acceptedFormats() {
        return ['.pdf', '.png','.jpg','.jpeg'];
    }
   
   handleSave(event) {
    if ((this.isEmiraatesDoc == false || this.isVechileDoc == false) && event.currentTarget.dataset.action == 'Approved') {
         this.errorMessage = 'Please upload mandatory files.';
        return;
    }
    //this.isDisabled = true;
    this.isLoading = true; // Show loader
    
    const details = {
        tradeCommercialNumber: this.tradeCoomercialNumber,
        caseId: this.caseId, // Initially might be null, but will get updated after creation
        emiratesId: this.emiratesId,
        mobileNumber: this.mobileNumber,
        actionlevel: event.currentTarget.dataset.action,
        plateCode: this.plateCode,
        plateNumber: this.plateNumber,
        plateSource: this.plateSource,
        mobileCode: this.selectedCountryCode
    };

    // Step 1: Create the case record
    saveDetails({ details: details })
        .then(result => {
            this.caseId = result; // Store the newly created case ID
            this.errorMessage = ''; // Clear any previous error

            if (this.filesToUpload.length > 0) {
                return this.uploadFiles(); // Step 2: Upload files using the new case ID
            } else {
                return Promise.resolve(); // No files to upload, just proceed
            }
        })
        .then(() => {
            this.isDisabled = true;
            this.isApprove = true;
            this.isRejected = true;
            setTimeout(() => {
            window.location.reload(); // Refresh page after 200ms for smooth transition
        }, 1000);
        })
        .catch(error => {
            let errorMessage = 'An error occurred while saving details.';

            if (error && error.body && error.body.message) {
                errorMessage = error.body.message;
            } else if (error && error.message) {
                errorMessage = error.message;
            }

            console.error('Error:', errorMessage);
            this.errorMessage = errorMessage;
        })
        .finally(() => { // 
            this.isLoading = false; // Hide loader after process completes
        });
        
}
    async fetchCaseDetails() {
        try {
            this.caseRecord = await getCaseDetails({ caseId: this.caseId });
        } catch (error) {
            this.error = 'Error fetching caseRecord details';
            console.error(error);
        } finally {
            this.isLoading = false;
        }
    }
     handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;

        // Show uploaded file details in the console or notify the user
        console.log('Uploaded Files:', uploadedFiles);
        alert(`${uploadedFiles.length} file(s) uploaded successfully.`);
    }
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }


    handleClose() {
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }
    get formattedCreatedDate() {
    return this.caseRecord?.CreatedDate ? new Date(this.caseRecord.CreatedDate).toLocaleString() : '';
}
   get formattedexpirydate() {
    if (this.caseRecord?.CreatedDate && this.caseRecord?.Permit_Validaity__c) {
        const createdDate = new Date(this.caseRecord.CreatedDate);
        const validityDays = parseInt(this.caseRecord.Permit_Validaity__c, 10);

        // Add the validity days to the created date
        createdDate.setDate(createdDate.getDate() + validityDays);

        // Return the formatted expiry date
        return createdDate.toLocaleDateString();  // Adjust formatting if needed
    }
    return '';
}
   get formattedLastModifiedDate() {
    return this.caseRecord?.LastModifiedDate ? new Date(this.caseRecord.LastModifiedDate).toLocaleString() : '';
}
    get minDate() {
        const today = new Date();
        return today.toISOString().split('T')[0];  // Returns 'YYYY-MM-DD'
    }
    validateFields() {
        const allInputs = this.template.querySelectorAll('lightning-input');
        let isValid = true;

        allInputs.forEach(input => {
            if (!input.checkValidity()) {
                input.reportValidity();
                isValid = false;
            }
        });

        return isValid;
    }
    validateEmiratesId(inputField) {
        const regexPattern = /^784-\d{4}-\d{7}-\d{1}$/;

        if (!this.emiratesId) {
            inputField.setCustomValidity('Emirates ID cannot be blank.');
        } else if (!regexPattern.test(this.emiratesId)) {
            inputField.setCustomValidity('Invalid Emirates ID format. Use 784-XXXX-XXXXXX-X.');
        } else {
            inputField.setCustomValidity('');
        }
        inputField.reportValidity(); // Shows validation message on the field
    }
    handleSubmitcheck() {
        // Get all input fields inside the component
        const allInputs = this.template.querySelectorAll('lightning-input');
        let isValid = true;

        allInputs.forEach(input => {
            if (!input.checkValidity()) { // Check if input is valid
                isValid = false;
            }
            input.reportValidity(); // Show error message if invalid
        });

        if (!isValid) {
            console.error('Please fill all required fields.');
            return;
        }

        console.log('Form submitted successfully with:', this.tradeCoomercialNumber);
        // Proceed with form submission logic here (e.g., calling Apex)
    }
    handleBack() {
        // Toggle visibility between components
    
        if (this.showSection2 ==true) {
           this.showSection2=false;
           this.showSection1=true;
        }else{
         setTimeout(() => {
            window.location.reload(); // Refresh page after 200ms for smooth transition
        }, 200);
        }
    }
    displaySection3() {
      this.validateInputs();
     
      if (!this.isNextDisabled) {
         if (this.mobileNumber.length !== 9 ) {
          this.errorMessage='Mobile number must be 9 digits';
          return;
         }
            this.errorMessage='';
            this.showSetion3=true;
            this.showSection2=false;
            this.showSection1=false; 
        } else {
           this.errorMessage='Please fill all required field.';
        }
    }
    displaySection2() {
      
       this.showSection2=true;
       this.showSection1=false;
    }
    validateInputs() {
        const requiredFields = [
            { field: 'emiratesId', value: this.emiratesId },
            { field: 'plateSource', value: this.plateSource },
            { field: 'plateCode', value: this.plateCode },
            { field: 'plateNumber', value: this.plateNumber },
            { field: 'mobileNumber', value: this.mobileNumber }
        ];

        let allValid = true;
        requiredFields.forEach((input) => {
            if (!input.value || input.value.trim() === '') {
                allValid = false;
            }
        });
        this.isNextDisabled = !allValid;
    }

     handleEmiratesInput(event) {
        let inputValue = event.target.value;
        
        // Remove any non-digit characters
        inputValue = inputValue.replace(/\D/g, '');

        // Add hyphens at the correct positions
        if (inputValue.length <= 3) {
            this.emiratesId = inputValue;
        } else if (inputValue.length <= 7) {
            this.emiratesId = `${inputValue.substring(0, 3)}-${inputValue.substring(3)}`;
        } else if (inputValue.length <= 14) {
            this.emiratesId = `${inputValue.substring(0, 3)}-${inputValue.substring(3, 7)}-${inputValue.substring(7)}`;
        } else {
            this.emiratesId = `${inputValue.substring(0, 3)}-${inputValue.substring(3, 7)}-${inputValue.substring(7, 14)}-${inputValue.substring(14, 15)}`;
        }
    }
}