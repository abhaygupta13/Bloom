import { LightningElement, track, wire } from 'lwc';
import getBookingSlots from '@salesforce/apex/AmenityCalendarController.getBookingSlots';
import getCommunitiesAndAmenities from '@salesforce/apex/AmenityCalendarController.getCommunitiesAndAmenities';
import getAmenitiesByProject from '@salesforce/apex/AmenityCalendarController.getAmenitiesByProject';

const TIME_SLOTS = [];
for (let h = 8; h < 24; h++) {
const start = `${h.toString().padStart(2, '0')}:00`;
const end = `${(h + 1).toString().padStart(2, '0')}:00`;
TIME_SLOTS.push({ start, end, label: `${formatHour(h)} - ${formatHour(h + 1)}` });
}

function formatHour(h) {
let suffix = h >= 12 ? 'PM' : 'AM';
let hour12 = h % 12 || 12;
return `${hour12} ${suffix}`;
}

export default class AmenityCalendar extends LightningElement {
@track viewMode = 'Today'; // 'Today', 'Week', 'Month'
@track days = [];
@track timeSlots = TIME_SLOTS;
@track loading = false;
@track error;
@track projects = [];
@track amenities = [];
@track selectedProject = '';
@track selectedAmenity = '';
isModalOpen = false;
options = [
{ label: 'Today', value: 'Today' },
{ label: 'Week', value: 'Week' },
{ label: 'Month', value: 'Month' }
];

connectedCallback() {
getCommunitiesAndAmenities()
    .then(result => {
        this.projects = result.communities.map(p => ({ label: p.Name, value: p.Id }));
    })
    .catch(error => {
        this.error = error.body ? error.body.message : error.message;
    });
}

handleProjectChange(event) {
this.selectedProject = event.detail.value;
this.selectedAmenity = '';
this.amenities = [];
getAmenitiesByProject({ projectId: this.selectedProject })
    .then(data => {
        this.amenities = data.map(a => ({ label: a.Name, value: a.Id }));
    })
    .catch(error => {
        this.error = error.body ? error.body.message : error.message;
    });
}

handleAmenityChange(event) {
this.selectedAmenity = event.detail.value;
if (this.selectedProject && this.selectedAmenity) {
    this.loadData();
}
}

loadData() {
    this.loading = true;
    let startDate, endDate;
    const today = new Date();

    if (this.viewMode === 'Today') {
        startDate = endDate = today.toISOString().slice(0, 10);
    } else if (this.viewMode === 'Week') {
        const start = new Date(today);
        start.setDate(today.getDate() - today.getDay());
        const end = new Date(start);
        end.setDate(start.getDate() + 6);
        startDate = start.toISOString().slice(0, 10);
        endDate = end.toISOString().slice(0, 10);
    } else if (this.viewMode === 'Month') {
        const start = new Date(today.getFullYear(), today.getMonth(), 1);
        const end = new Date(today.getFullYear(), today.getMonth() + 1, 0);
        startDate = start.toISOString().slice(0, 10);
        endDate = end.toISOString().slice(0, 10);
    }

    getBookingSlots({
        startDate,
        endDate,
        projectId: this.selectedProject,
        amenityId: this.selectedAmenity
    })
        .then(jsonString => {
            const slots = JSON.parse(jsonString);
            this.days = this.buildCalendar(slots, startDate, endDate);
            this.error = null;
        })
        .catch(error => {
            this.error = error.body ? error.body.message : error.message;
            this.days = [];
        })
        .finally(() => {
            this.loading = false;
        });
}


buildCalendar(slots, startDateStr, endDateStr) {
const startDate = new Date(startDateStr);
const endDate = new Date(endDateStr);
const days = [];

// Create a map of date -> slots
const slotsByDate = {};
slots.forEach(slot => {
if (!slotsByDate[slot.date]) {
    slotsByDate[slot.date] = [];
}
slotsByDate[slot.date].push(slot);
});

for (let d = new Date(startDate); d <= endDate; d.setDate(d.getDate() + 1)) {
const dateKey = d.toISOString().slice(0, 10);
const daySlots = [];

for (const ts of this.timeSlots) {
    const matchingSlot = (slotsByDate[dateKey] || []).find(s => s.startTime.startsWith(ts.start));
    daySlots.push({
        ...ts,
        status:  matchingSlot.status,
        className: this.getSlotClass( matchingSlot.status),
        caseNumber:matchingSlot.bookingNumber
    });
}

days.push({
    date: dateKey,
    displayLabel: d.toLocaleDateString(undefined, { day: '2-digit', month: 'short', year: 'numeric' }),
    slots: daySlots
});
}

return days;
}

getSlotClass(status) {
 if(status === 'Confirmed' || status==='Submitted'){
    
    return 'slot-booked' ;
}
else if(status === 'Cancelled' || status==='Rejected'){
    return 'slot-rejected';
}
}

handleViewChange(event) {
this.viewMode = event.target.value;
if (this.selectedProject && this.selectedAmenity) {
        this.loadData();
    }
}
handleOpenModal() {
        this.isModalOpen = true;
    }

    handleModalClose() {
        this.isModalOpen = false;
    }


}