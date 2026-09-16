import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getDashboardIdByName from '@salesforce/apex/DashboardController.getDashboardIdByName';

export default class ProjectDashboardNavigator extends NavigationMixin(LightningElement) {
    // Define your Project Labels and the exact Dashboard Titles
    @track projectOptions = [
        { label: 'Cordoba', value: 'Cordoba Handover Management' },
      
        { label: 'Toledo', value: 'Toledo Handover Management' },
          { label: 'Casares', value: 'Casares Handover Management Dashboard' },
        { label: 'Bloom Arjaan', value: 'Bloom Arjaan Handover Management Dashboard' }
    ];

    handleProjectChange(event) {
        const selectedDashboardName = event.detail.value;

        // Fetch the ID dynamically from Apex
        getDashboardIdByName({ dashboardName: selectedDashboardName })
            .then(dashboardId => {
                if (dashboardId) {
                    this.navigateToDashboard(dashboardId);
                } else {
                    console.error('Dashboard not found: ' + selectedDashboardName);
                }
            })
            .catch(error => {
                console.error('Error fetching dashboard ID', error);
            });
    }

    navigateToDashboard(dashId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: dashId,
                objectApiName: 'Dashboard',
                actionName: 'view'
            }
        });
    }
}