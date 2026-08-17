import { LightningElement, api, wire } from 'lwc';
import getPaymentPlanSummary from '@salesforce/apex/LeasingOrderController.getPaymentPlanSummary';

const COLUMNS = [
    {
        label: 'Total',
        fieldName: 'total'
    },
    {
        label: 'Installment Amount',
        fieldName: 'totalInstallmentAmount'
    },
    {
        label: 'Due Amount',
        fieldName: 'totalDueAmount'
    },
    {
        label: 'Cleared Amount',
        fieldName: 'totalClearedAmount'
    }
];

export default class LeasingOrderPaymentSummary extends LightningElement {
    @api recordId;

    summary;
    error;
    columns = COLUMNS;

    @wire(getPaymentPlanSummary, { leasingOrderId: '$recordId' })
    wiredSummary({ data, error }) {
        if (data) {
            this.summary = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.summary = undefined;
        }
    }

    get summaryData() {
        if (!this.summary) {
            return [];
        }

        return [
            {
                id: 'summary',
                totalInstallmentAmount: this.summary.totalInstallmentAmount,
                totalDueAmount: this.summary.totalDueAmount,
                totalClearedAmount: this.summary.totalClearedAmount,
                total: 'Total'
            }
        ];
    }

    get errorMessage() {
        if (!this.error) {
            return '';
        }

        if (this.error.body && this.error.body.message) {
            return this.error.body.message;
        }

        return 'An unexpected error occurred while loading payment summary.';
    }
}