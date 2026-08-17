import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

import validateForNextReview from '@salesforce/apex/ComplaintReviewValidatorController.validateForNextReview';
import getTeamValues from '@salesforce/apex/ComplaintReviewValidatorController.getTeamValues';
import getUsersByTeam from '@salesforce/apex/ComplaintReviewValidatorController.getUsersByTeam';
import shouldShowTeamSection from '@salesforce/apex/ComplaintReviewValidatorController.shouldShowTeamSection';
import createSelectedTeamTask from '@salesforce/apex/ComplaintReviewValidatorController.createSelectedTeamTask';

export default class ComplaintReviewStepValidator extends NavigationMixin(
    LightningElement
) {
    isLoading = false;

    currentRecordId;
    showTeamSection = false;

    teamOptions = [];
    userOptions = [];

    selectedTeam;
    selectedUserId;
    commentText = '';

    @api
    set recordId(value) {
        this.currentRecordId = value;

        if (value) {
            this.initializeComponent();
        }
    }

    get recordId() {
        return this.currentRecordId;
    }

    async initializeComponent() {
        await Promise.all([
            this.fetchTeamOptions(),
            this.loadTeamSectionVisibility()
        ]);
    }

    async fetchTeamOptions() {
        try {
            const result = await getTeamValues();

            this.teamOptions = Object.entries(result).map(
                ([value, label]) => ({
                    label,
                    value
                })
            );
        } catch (error) {
            console.error('Error fetching teams:', error);
        }
    }

    async loadTeamSectionVisibility() {
        try {
            this.showTeamSection = await shouldShowTeamSection({
                caseId: this.currentRecordId
            });

            if (!this.showTeamSection) {
                this.resetTeamSection();
            }
        } catch (error) {
            console.error(
                'Error determining team section visibility:',
                error
            );
        }
    }

    async handleTeamChange(event) {
        this.selectedTeam = event.detail.value;
        this.selectedUserId = null;
        this.userOptions = [];

        if (!this.selectedTeam) {
            return;
        }

        try {
            this.userOptions = await getUsersByTeam({
                team: this.selectedTeam
            });
        } catch (error) {
            console.error('Error fetching users:', error);
            this.userOptions = [];
        }
    }

    handleUserChange(event) {
        this.selectedUserId = event.detail.value;
    }

    handleCommentChange(event) {
        this.commentText = event.target.value;
    }

    async checkDeferralStatus() {
        if (!this.currentRecordId) {
            return;
        }

        this.isLoading = true;

        try {
            const result = await validateForNextReview({
                recordId: this.currentRecordId
            });

            this.showToast(
                result.status === 'success'
                    ? 'Success'
                    : 'Error',
                result.message,
                result.status === 'success'
                    ? 'success'
                    : 'error'
            );

            if (result.status !== 'success') {
                return;
            }

            if (this.showTeamSection) {
                if (!this.selectedTeam || !this.selectedUserId) {
                    this.showToast(
                        'Error',
                        'Please select Team and User.',
                        'error'
                    );
                    return;
                }

                await createSelectedTeamTask({
                    caseId: this.currentRecordId,
                    team: this.selectedTeam,
                    userId: this.selectedUserId,
                    comments: this.commentText
                });

                // Immediately update UI without page refresh
                this.resetTeamSection();
                this.showTeamSection = false;
            }

            await notifyRecordUpdateAvailable([
                { recordId: this.currentRecordId }
            ]);

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.currentRecordId,
                    actionName: 'view'
                }
            });
        } catch (error) {
            console.error('Error:', error);

            this.showToast(
                'Error',
                error?.body?.message ||
                    'An unexpected error occurred.',
                'error'
            );
        } finally {
            this.isLoading = false;
            this.closeComponent();
        }
    }

    resetTeamSection() {
        this.selectedTeam = null;
        this.selectedUserId = null;
        this.commentText = '';
        this.userOptions = [];
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
                mode: 'dismissable'
            })
        );
    }

    closeComponent() {
        this.dispatchEvent(
            new CloseActionScreenEvent()
        );
    }
}