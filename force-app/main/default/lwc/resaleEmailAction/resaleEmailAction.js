import { LightningElement, api, track } from 'lwc';
import getEmailTemplates from '@salesforce/apex/ResaleEmailActionController.getEmailTemplates';
import getEmailBody from '@salesforce/apex/ResaleEmailActionController.getEmailBody';
import sendEmailUsingTemplate from '@salesforce/apex/ResaleEmailActionController.sendEmailUsingTemplate';
import getCaseLegalStatus from '@salesforce/apex/ResaleEmailActionController.getCaseLegalStatus';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ResaleEmailActionController extends LightningElement {
    @api recordId;
    @track templateOptions = [];
    @track selectedTemplateId = '';
    @track emailSubject = '';
    @track emailBody = '';
    @track toAddress = '';
    @track ccAddress = '';
    @track isLoading = false;
    @track legalStatus = '';

    connectedCallback() {
        this.loadTemplates();
        this.disableClose = true;

        // Fetch Case Unit Legal Status
        getCaseLegalStatus({ caseId: this.recordId })
            .then(status => {
                this.legalStatus = status;
            })
            .catch(error => {
                console.error('Error fetching legal status:', error);
            });
    }

    renderedCallback() {
        const container = this.template.querySelector('.email-body');
        if (!container || !this.emailBody) return;

        // Only (re)inject if different to avoid loops
        if (container.innerHTML !== this.emailBody) {
            container.innerHTML = this.emailBody;

            // Fix RTL/LTR blocks (keeps your earlier alignment fix)
            container.querySelectorAll('[dir="rtl"]').forEach(el => {
                el.style.direction = 'rtl';
                el.style.textAlign = 'right';
            });
            container.querySelectorAll('[dir="ltr"]').forEach(el => {
                el.style.direction = 'ltr';
                el.style.textAlign = 'left';
            });

            const lists = container.querySelectorAll('ul, ol');
            lists.forEach(list => {
                const isRTL =
                    list.getAttribute('dir') === 'rtl' ||
                    (list.closest('[dir="rtl"]') ? true : false);

                // Force proper list rendering
                list.style.listStyleType = list.tagName.toLowerCase() === 'ol' ? 'decimal' : 'disc';
                list.style.listStylePosition = isRTL ? 'inside' : 'outside';

                // Ensure bullets aren’t clipped by zero padding from resets
                list.style.paddingLeft  = isRTL ? '0'      : '1.25rem';
                list.style.paddingRight = isRTL ? '1.25rem': '0';
                list.style.marginTop = '0.5rem';
                list.style.marginBottom = '0.5rem';
            });

            // Some normalizers set li to display:block; force list-item so markers show
            container.querySelectorAll('li').forEach(li => {
                li.style.display = 'list-item';
                li.style.listStyleType = 'inherit';
            });
        }
    }

    handleCloseModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    loadTemplates() {
        this.isLoading = true;
        getEmailTemplates()
            .then(result => {
                this.templateOptions = result.map(t => ({
                    label: t.name,
                    value: t.id
                }));
            })
            .catch(error => {
                this.showToast('Error Loading Templates', this.parseError(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleTemplateChange(event) {
        this.selectedTemplateId = event.detail.value;
        if (this.selectedTemplateId) {
            this.loadEmailBody();
        }
    }

    handleToChange(event) {
        this.toAddress = event.target.value;
    }

    handleCcChange(event) {
        this.ccAddress = event.target.value;
    }

    handleSubjectChange(event) {
        this.emailSubject = event.target.value;
    }

    loadEmailBody() {
        this.isLoading = true;
        getEmailBody({ templateId: this.selectedTemplateId, caseId: this.recordId })
            .then(result => {
                this.emailBody = result.body;
                this.emailSubject = result.subject;
            })
            .catch(error => {
                this.showToast('Error Loading Template Body', this.parseError(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleSend() {
        if (!this.recordId) {
            this.showToast('Validation Error', 'Record Id not available yet. Please try again.', 'error');
            return;
        }

        this.isLoading = true;
        getCaseLegalStatus({ caseId: this.recordId })
            .then(result => {
                if (result === 'With Legal') {
                    this.showToast(
                        'Validation Error',
                        'Email can\'t be sent since the Unit is with Legal.',
                        'error'
                    );
                    throw new Error('Validation failed: Unit is with Legal');
                }
                return sendEmailUsingTemplate({
                    caseId: this.recordId,
                    subject: this.emailSubject,
                    body: this.emailBody,
                    toAddress: this.toAddress,
                    ccAddress: this.ccAddress
                });
            })
            .then(() => {
                // Will not run if validation failed above
                this.showToast('Email Sent', 'The email was sent successfully.', 'success');
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                // Show error only if it’s not validation
                if (error?.message?.includes('Validation failed')) {
                    // Already handled by toast, so ignore
                    return;
                }
                this.showToast('Error Sending Email', this.parseError(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant,
            mode: 'dismissable'
        }));
    }

    parseError(error) {
        if (error?.body?.message) {
            return error.body.message;
        }
        return 'An unexpected error occurred.';
    }
}