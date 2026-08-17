import { LightningElement } from 'lwc';
import uploadSchedule from '@salesforce/apex/BusinessHoursScheduleController.uploadSchedule';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSampleCSVContentVersionId from '@salesforce/apex/BusinessHoursScheduleController.getSampleCSVContentVersionId';

export default class ContactCenterScheduleUpload extends LightningElement {

    showModal = false;    
    fileData;
    fileName = '';
    isUploading = false;
    sampleCSVVersionId;
    

    // NEW CHANGE
    // VALIDATE BUTTON ENABLE/DISABLE
    isValidated = false;

    // OPEN MODAL
    openModal() {
        this.showModal = true;
    }
    get disableSubmit() {
        return !this.isValidated;
    }

    get disableValidate() {
        return this.isValidated;
    }
    // CLOSE MODAL
    closeModal() {

        this.showModal = false;
        this.fileData = null;
        this.fileName = '';
        this.isValidated = false;
        
        const fileInput =
            this.template.querySelector(
                'lightning-input[type="file"]'
            );
       
        if(fileInput) {
            fileInput.value = null;
        }
    }
    connectedCallback() {
        getSampleCSVContentVersionId()
            .then(result => {
                this.sampleCSVVersionId = result;
            })
            .catch(error => {
                console.error('Error loading Content Version Id', error);
            });
    }
    openFilePicker(){
        this.template.querySelector('.fileInput').click();
    }

    // HANDLE FILE CHANGE
    handleFileChange(event) {

        const file = event.target.files[0];
        if(!file) {
            return;
        }

        // NEW CHANGE
        // RESET VALIDATION 
        this.isValidated = false;
        // RESET
        this.fileData = null;
        this.fileName = '';

        // CSV VALIDATION
        if(!file.name.toLowerCase().endsWith('.csv')) {

            this.showToast(
                'Error',
                'Please upload CSV file only.',
                'error'
            );
            return;
        }

        this.fileName = file.name;
        const reader = new FileReader();

        reader.onload = () => {
          this.fileData = {
                filename: file.name,
                text: reader.result
            };

            this.showToast(
                'Success',
                'CSV file selected successfully.',
                'success'
            );
        };

        reader.onerror = () => {
            this.showToast(
                'Error',
                'Unable to read file.',
                'error'
            );
        };
        reader.readAsText(file);
    }

    // NEW CHANGE
    // VALIDATE FILE BEFORE SUBMIT
    validateFile() {
        if( !this.fileData ||  !this.fileData.text        ) {

            this.showToast(
                'Error',
                'Please select CSV file.',
                'error'
            );
            return;
        }

        const csvText = this.fileData.text;

        // EMPTY FILE
        if(!csvText || csvText.trim() === '') {
            this.showToast(
                'Error',
                'CSV file is empty.',
                'error'
            );
            return;
        }

        //const rows = csvText.split(/\r\n|\n/);
        //const rows = csvText.split(/\r\n|\n|\r/);
        //const rows = csvText.replace(/\r/g, '\n').split('\n');
        const rows = csvText .replace(/\r\n/g, '\n') .replace(/\r/g, '\n') .split('\n') .filter(row => row.trim() !== '');
        // INVALID CSV
        if(rows.length < 2) {
            this.showToast(
                'Error',
                'Invalid CSV format.',
                'error'
            );
            return;
        }

        // HEADER VALIDATION
        const header = rows[0] .replace(/\r/g, '') .split(',');
        if(header.length < 6) {
        this.showToast(
            'Error',
            'Invalid CSV header format.',
            'error'
        );
        return;
        }

        if(    header[0].trim().toLowerCase() !== 'agentname' ||
            header[1].trim().toLowerCase() !== 'email' ||
            header[2].trim().toLowerCase() !== 'startdate' ||
            header[3].trim().toLowerCase() !== 'starttime' ||
            header[4].trim().toLowerCase() !== 'enddate' ||
            header[5].trim().toLowerCase() !== 'endtime') {
                this.showToast(
                    'Error',
                    'Invalid CSV header names.',
                    'error'
                );
            return;
        }
        // ROW VALIDATION
        for(let i = 1; i < rows.length; i++) {
            if(!rows[i] || rows[i].trim() === '') {
                continue;
            }

            const cols =
                rows[i]
                .replace(/\r/g, '')
                .split(',');

            if(cols.length < 6) {
                continue;
            }

            const agentName = cols[0]?.trim();
            const email = cols[1]?.trim();

            const startDate = cols[2]?.trim();
            const startTime = cols[3]?.trim();

            const endDate = cols[4]?.trim();
            const endTime = cols[5]?.trim();

            // EMAIL MANDATORY
            if(!email) {

                this.showToast(
                    'Error',
                    'Email field is mandatory. Please fill all email fields in CSV file.',
                    'error'
                );
                return;
            }
        
            if(!startDate) {
                this.showToast(
                    'Error',
                    'Start Date is mandatory.',
                    'error'
                );
                return;
            }

            if(!startTime) {
                this.showToast(
                    'Error',
                    'Start Time is mandatory.',
                    'error'
                );
                return;
            }

            if(!endDate) {
                this.showToast(
                    'Error',
                    'End Date is mandatory.',
                    'error'
                );
                return;
            }

            if(!endTime) {
                this.showToast(
                    'Error',
                    'End Time is mandatory.',
                    'error'
                );
                return;
            }

            // EMAIL FORMAT VALIDATION
            const emailRegex =
                /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;

            if(!emailRegex.test(email)) {
                this.showToast(
                    'Error',
                    'Invalid email format found in CSV file. Please check and upload again.',
                    'error'
                );
                return;
            }

                //const dateRegex = /^(0?[1-9]|[12][0-9]|3[01])-(0?[1-9]|1[0-2])-\d{4}$/;
                const dateRegex =/^(0?[1-9]|[12][0-9]|3[01])[\/-](0?[1-9]|1[0-2])[\/-]\d{4}$/;
                const timeRegex =/^(0?[1-9]|1[0-2]):([0-5][0-9])\s?(AM|PM)$/i;
                if(!timeRegex.test(startTime)) {
                    this.showToast(
                        'Error',
                        'Invalid Start Time format. Use HH:MM AM/PM.',
                        'error'
                    );
                    return;
                }

                if(!timeRegex.test(endTime)) {
                    this.showToast(
                        'Error',
                        'Invalid End Time format. Use HH:MM AM/PM.',
                        'error'
                    );
                    return;
                }

            
            if(!dateRegex.test(startDate)) {
                this.showToast(
                    'Error',
                    'Invalid Start Date format. Use DD-MM-YYYY.',
                    'error'
                );
                return;
            }

            if(!dateRegex.test(endDate)) {
                this.showToast(
                    'Error',
                    'Invalid End Date format. Use DD-MM-YYYY.',
                    'error'
                );
                return;
            }

            const start =
                this.convertToDate(
                    startDate,
                    startTime
                );

            const end =
                this.convertToDate(
                    endDate,
                    endTime
                );
                

                if(end <= start) {
                    this.showToast(
                        'Error',
                        'End Date Time should be greater than Start Date Time.',
                        'error'
                    );
                    return;
                }

        }

        

        // NEW CHANGE
        // ENABLE SUBMIT BUTTON
        this.isValidated = true;
        this.showToast(
            'Success',
            'CSV validated successfully.',
            'success'
        );
    }
    convertToDate(dateStr, timeStr) {
        const [day, month, year] = dateStr.split(/[\/-]/).map(Number);
        let [time, ampm] = timeStr.split(' '), [hour, minute] = time.split(':').map(Number);
        ampm = ampm.toUpperCase();
        if(ampm === 'PM' && hour < 12) hour += 12;
        if(ampm === 'AM' && hour === 12) hour = 0;
        return new Date(year, month - 1, day, hour, minute);
    }
  
    // SUBMIT FILE AFTER VALIDATION
    uploadFile() {
        debugger
        if(!this.isValidated) {
            this.showToast(
                'Error',
                'Please validate CSV file first.',
                'error'
            );
            return;
        }

        this.isUploading = true;
        uploadSchedule({
            csvText: this.fileData.text,
            fileName: this.fileData.filename
        })

        .then(result => {
            this.showToast(
                'Success',
                result,
                'success'
            );
        
             setTimeout(() => {
            this.closeModal();
            window.location.reload();
            }, 2000); // wait 3 seconds

            // NEW CHANGE
            // DO NOT CLOSE MODAL AUTOMATICALLY
            // USER CAN SEE SUCCESS MESSAGE
        })

        .catch(error => {

            let message =
                'Unknown Error';

            if(error?.body?.message) {
                message = error.body.message;
            }
            else if(error?.message) {
                message = error.message;
            }

            this.showToast(
                'Error',
                message,
                'error'
            );
        })

        .finally(() => {
            this.isUploading = false;
        });
    }

    downloadSampleFile() {

    if (!this.sampleCSVVersionId) {
        this.showToast(
            'Error',
            'Sample file configuration is missing.',
            'error'
        );
        return;
    }

    window.open(
        '/sfc/servlet.shepherd/version/download/' +
        this.sampleCSVVersionId,
        '_blank'
    );
}

    // TOAST
    showToast(
        title,
        message,
        variant
    ) {

        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}