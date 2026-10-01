import { LightningElement, wire, api } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getPicklistvalue from "@salesforce/apex/Utilities.getPicklistValues";
import createAppointment from "@salesforce/apex/AppointmentController.createAppointment";
import getAvailableSlotsTime from "@salesforce/apex/AppointmentController.getAvailableSlotsTime";
import USER_ID from "@salesforce/user/Id";

export default class AppointmentAction extends LightningElement {
  // Component state and appointment fields
  @api recordId;
  isLoading = false;

  assignedToId = USER_ID;
  subject = "";
  startDate = "";
  startTime = "";
  endDate = "";
  endTime = "";
  appointmentType = "";
  appointmentMode = "";
  location = "";
  description = "";
  errorMessage = "";
  startDateTime = "";
  endDateTime = "";

  selectedSlotId = "";
  appointmentDate = "";

  isSlotDisabled = true;

  // Picklist and slot options
  appointmentTypeOptions = [];
  appointmentModeOptions = [];
  locationOptions = [];
  timeOptions = [];
  availableSlots = [];
  allAppointmentModeOptions = [];

  // Constants used for appointment creation
  BOOKING_SOURCE_SELF_BOOKING = "Self Booking";
  BOOKING_SOURCE_OTHERS = "Others";
  APPOINTMENT_STATUS_SCHEDULED = "Scheduled";

  // Returns today's date in YYYY-MM-DD format
  get minDate() {
    const today = new Date();
    return today.toLocaleDateString("en-CA");
  }

  // Returns the appropriate placeholder for the slot dropdown
  get slotPlaceholder() {
    if (!this.appointmentDate || this.appointmentDate < this.minDate) {
      return "Please select a valid appointment date";
    } else if (this.isLoading) {
      return "Loading available slots...";
    } else if (this.timeOptions && this.timeOptions.length > 0) {
      return "Select a time slot";
    }

    return "No slots available";
  }

  // Determines whether the slot field should be required
  get isSlotRequired() {
    return this.availableSlots && this.availableSlots.length > 0;
  }

  // Determines whether Location should be required
  get isLocationRequired() {
    return this.appointmentMode === "Offline";
  }

  // Determines whether manual date/time fields should be displayed
  get showManualFields() {
    const isValidDate =
      this.appointmentDate && this.appointmentDate >= this.minDate;

    return (
      isValidDate &&
      this.isSlotDisabled &&
      this.timeOptions.length === 0 &&
      !this.isLoading
    );
  }

  // Loads Appointment Type picklist values
  @wire(getPicklistvalue, {
    objName: "Event",
    fieldName: "AppointmentType__c"
  })
  wiredAppointmentTypeValues({ data, error }) {
    if (data) {
      this.appointmentTypeOptions = this.toOptions(data);
    } else if (error) {
      console.error(error);
      this.showToast("Error", "Failed to load appointment types", "error");
    }
  }

  // Loads Appointment Mode picklist values
  @wire(getPicklistvalue, {
    objName: "Event",
    fieldName: "AppointmentMode__c"
  })
  wiredAppointmentModeValues({ data, error }) {
    if (data) {
      // Store all original Appointment Mode values
      this.allAppointmentModeOptions = this.toOptions(data);

      // Initially show all Appointment Mode values
      this.appointmentModeOptions = [...this.allAppointmentModeOptions];
    } else if (error) {
      console.error(error);
      this.showToast("Error", "Failed to load appointment modes", "error");
    }
  }

  // Loads Location picklist values
  @wire(getPicklistvalue, {
    objName: "Event",
    fieldName: "Location__c"
  })
  wiredLocationValues({ data, error }) {
    if (data) {
      this.locationOptions = this.toOptions(data);
    } else if (error) {
      console.error(error);
      this.showToast("Error", "Failed to load locations", "error");
    }
  }

  // Converts picklist values into combobox options
  toOptions(data) {
    return Object.entries(data).map(([label, value]) => ({
      label,
      value
    }));
  }

  // Validates required fields and appointment date/time
  validateReqFields() {
    this.errorMessage = "";

    const inputFields = [
      ...this.template.querySelectorAll(
        "lightning-input, lightning-combobox, lightning-textarea"
      )
    ];
    let allValid = true;

    inputFields.forEach((field) => {
      const fieldValid = field.reportValidity();
      allValid = fieldValid ? allValid : false;
    });

    if (!allValid) {
      this.errorMessage = "Please fill in all required fields.";
      return false;
    }
    return true;
  }

  // Loads available appointment slots for the selected user and date
  loadAvailableTimes() {
    if (!this.assignedToId || !this.appointmentDate) {
      return;
    }

    this.isLoading = true;

    getAvailableSlotsTime({
      userId: this.assignedToId,
      selectedDate: this.appointmentDate
    })
      .then((result) => {
        if (result && result.length > 0) {
          this.availableSlots = result;

          this.timeOptions = result.map((slot) => {
            const startTime = new Date(
              slot.StartDateTime__c
            ).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
            const endTime = new Date(slot.EndDateTime__c).toLocaleTimeString(
              [],
              { hour: "2-digit", minute: "2-digit" }
            );

            return { label: `${startTime} - ${endTime}`, value: slot.Id };
          });

          this.isSlotDisabled = false;
        } else {
          this.selectedSlotId = "";
          this.timeOptions = [];
          this.isSlotDisabled = true;
        }
      })
      .catch((error) => {
        console.error(error);
        this.showToast("Error", "Failed to load available slots", "error");
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  // Creates the appointment using the entered date and time or based on selected slot details
  async handleSave() {
    if (!this.validateReqFields()) return;

    if (this.selectedSlotId === "" || !this.selectedSlotId) {
      this.startDateTime = new Date(`${this.startDate}T${this.startTime}`).toISOString();
      this.endDateTime = new Date(`${this.endDate}T${this.endTime}`).toISOString();
    }
    if (!this.startDateTime || !this.endDateTime) {
      this.errorMessage = "Please provide a valid start and end date/time.";
      return;
    }

    if (new Date(this.endDateTime) <= new Date(this.startDateTime)) {
      this.errorMessage = "End date/time must be after start date/time.";
      return;
    }

    const appointmentPayload = {
      Subject: this.subject,
      StartDateTime: this.startDateTime,
      EndDateTime: this.endDateTime,
      AppointmentType__c: this.appointmentType,
      AppointmentMode__c: this.appointmentMode,
      Location__c: this.location,
      Location: this.location,
      Description: this.description,
      OwnerId: this.assignedToId,
      AppointmentSlot__c: this.selectedSlotId,
      BookingSource__c:
        USER_ID === this.assignedToId ? this.BOOKING_SOURCE_SELF_BOOKING : this.BOOKING_SOURCE_OTHERS,
      AppointmentStatus__c: this.APPOINTMENT_STATUS_SCHEDULED
    };

    this.isLoading = true;

    try {
      await createAppointment({
        appointment: appointmentPayload,
        recordId: this.recordId
      });
      this.showToast(
        "Success",
        "Appointment scheduled successfully.",
        "success"
      );
      this.dispatchEvent(new CloseActionScreenEvent());
    } catch (error) {
      this.errorMessage =
        error?.body?.message || "Something went wrong while saving.";
      this.showToast("Error", this.errorMessage, "error");
    } finally {
      this.isLoading = false;
    }
  }

  resetAppointmentFields() {
    this.selectedSlotId = "";
    this.appointmentType = "";
    this.appointmentSlot = "";
    this.startDate = "";
    this.startTime = "";
    this.endDate = "";
    this.endTime = "";
    this.appointmentMode = "";
    this.location = "";
    this.description = "";
    this.timeOptions = [];
    this.availableSlots = [];
    this.isSlotDisabled = true;

    // Restore all Appointment Mode values
    this.appointmentModeOptions = [...this.allAppointmentModeOptions];
  }

  // Handles subject changes
  handleSubjectChange(event) {
    this.subject = event.target.value;
  }

  // Handles start date changes
  handleStartDateChange(event) {
    this.startDate = event.target.value;
  }

  // Handles start time changes
  handleStartTimeChange(event) {
    this.startTime = event.target.value;
  }

  // Handles end date changes
  handleEndDateChange(event) {
    this.endDate = event.target.value;
  }

  // Handles end time changes
  handleEndTimeChange(event) {
    this.endTime = event.target.value;
  }

  // Handles appointment type changes
  handleAppointmentTypeChange(event) {
    this.appointmentType = event.detail.value;
  }

  // Handles appointment mode changes
  handleAppointmentModeChange(event) {
    this.appointmentMode = event.detail.value;
  }

  // Handles location changes
  handleLocationChange(event) {
    this.location = event.detail.value;
  }

  // Handles description changes
  handleDescriptionChange(event) {
    this.description = event.target.value;
  }

  // Handles Assigned To changes
  handleAssignedToChange(event) {
    this.assignedToId = event.detail.recordId;

    // Changing Assigned To resets the appointment fields
    this.appointmentDate = "";

    this.resetAppointmentFields();
  }

  // Handles appointment date changes and reloads available slots
  handleAppointmentDateChange(event) {
    this.resetAppointmentFields();

    this.appointmentDate = event.target.value;

    this.startDate = this.appointmentDate;
    this.endDate = this.appointmentDate;

    if (this.appointmentDate >= this.minDate) {
      this.loadAvailableTimes();
    }
  }

  // Handles slot selection
  handleSlotChange(event) {
    this.selectedSlotId = event.detail.value;

    const selectedSlot = this.availableSlots.find(
      (slot) => slot.Id === this.selectedSlotId
    );

    if (selectedSlot) {
      this.startDateTime = selectedSlot.StartDateTime__c;
      this.endDateTime = selectedSlot.EndDateTime__c;

      const modes = selectedSlot.Mode__c ? selectedSlot.Mode__c.split(";") : [];

      this.appointmentModeOptions = modes.map((mode) => ({
        label: mode.trim(),
        value: mode.trim()
      }));
      // Clear previously selected mode
      this.appointmentMode = "";
    }
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }
}