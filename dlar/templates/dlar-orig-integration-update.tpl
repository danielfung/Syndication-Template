			iacucQ = iacucQ.elements().item(1);
			?'DLAR.iacucQ protocol found =>'+iacucQ.ID+'\n';
			//update fields below total animal #.

			/*
				1a. protocol team members => first clear the set, then re-add each study team member
					contacts => first clear the set then re-add each study team member
			*/

			var protocolTeamMembers = iacucQ.customAttributes.protocolTeamMembers;
			if(protocolTeamMembers == null){
				var studyTeamMemberInfo = _StudyTeamMemberINfo.createEntitySet();
				iacucQ.setQualifiedAttribute('customAttributes.protocolTeamMembers', studyTeamMemberInfo);
				protocolTeamMembers = iacucQ.customAttributes.protocolTeamMembers;
				?'created iacucQ.customAttributes.protocolTeamMembers eset=>'+protocolTeamMembers+'\n';
			}
			else{
				?'DLAR(IACUC) protocolTeamMembers => '+protocolTeamMembers+'\n';
				protocolTeamMembers.removeAllElements();
				?'removing all protocolTeamMembers and readding from eset => '+protocolTeamMembers+'\n';;
			}

			var contactSet = iacucQ.contacts;
			if(contactSet == null){
				iacucQ.contacts = Person.createEntitySet();
				?'created contacts eset => '+iacucQ.contacts+'\n';
				contactSet = iacucQ.contacts;
			}
			else{
				?'DLAR(IACUC) contacts => '+contactSet+'\n';
				contactSet.removeAllElements();
				?'removing all contacts from list \n';
			}

			{{#each studyTeamMembers}}
				{{#if studyTeamMember.userId}}

					var person = ApplicationEntity.getResultSet("Person").query("userID = '{{studyTeamMember.userId}}'");
					if(person.count() > 0){
						person = person.elements().item(1);
						contactSet.addElement(person);
						?'added person to contact set =>'+person+'\n';

						var studyTeam = _StudyTeamMemberINfo.createEntity();
						?'create entity studyTeamMemberInfo => '+studyTeam+'\n';

						studyTeam.setQualifiedAttribute('customAttributes.studyTeamMember', person);
						?'set person to studyTeamMember => '+person+'\n';

						var iacucAuthorizedToOrderAnimals = "{{isAuthorizedToOrderAnimals}}";
						var iacucInvolvedInAnimalHandling = "{{isInvolvedInAnimalHandling}}";
						var dlarAuthorizedToOrderAnimals;
						var dlarInvolvedInAnimalHandling;

						if(iacucAuthorizedToOrderAnimals == "1"){
							dlarAuthorizedToOrderAnimals = true;
						}
						else{
							dlarAuthorizedToOrderAnimals = false;
						}

						if(iacucInvolvedInAnimalHandling == "1"){
							dlarInvolvedInAnimalHandling = true;
						}
						else{
							dlarInvolvedInAnimalHandling = false;
						}

						studyTeam.customAttributes.isAuthorizedToOrderAnimals = dlarAuthorizedToOrderAnimals;
						?'set isAuhtorizedToOrderAnimals => '+dlarAuthorizedToOrderAnimals+'\n';
						studyTeam.customAttributes.isInvolvedInAnimalHandling = dlarInvolvedInAnimalHandling;
						?'set isInvolvedInAnimalHandling => '+dlarInvolvedInAnimalHandling+'\n';

						protocolTeamMembers.addElement(studyTeam);
						?'added studyTeam to IACUC Study Team =>'+studyTeam+'\n';

					}
				{{/if}}
			{{/each}}

			{{#if investigator.studyTeamMember.userId}}
				var person = ApplicationEntity.getResultSet("Person").query("userID = '{{investigator.studyTeamMember.userId}}'").elements();
						
				var iacucInvolvedInAnimalHandling = '{{investigator.isInvolvedInAnimalHandling}}';
				var iacucAuthorizedToOrderAnimals = '{{investigator.isAuthorizedToOrderAnimals}}';
				var dlarAuthorizedToOrderAnimals;
				var dlarInvolvedInAnimalHandling;

				if(iacucAuthorizedToOrderAnimals == "1"){
					dlarAuthorizedToOrderAnimals = true;
				}
				else{
					dlarAuthorizedToOrderAnimals = false;
				}

				if(iacucInvolvedInAnimalHandling == "1"){
					dlarInvolvedInAnimalHandling = true;
				}
				else{
					dlarInvolvedInAnimalHandling = false;
				}

				if(person.count() > 0){
					person = person.item(1);
					contactSet.addElement(person);
					?'added person to contact set =>'+person+'\n';

					var studyTeam = _StudyTeamMemberINfo.createEntity();
					?'create entity studyTeamMemberInfo => '+studyTeam+'\n';
					studyTeam.setQualifiedAttribute('customAttributes.studyTeamMember', person);
					?'set person to studyTeamMember => '+person+'\n';
					studyTeam.customAttributes.isAuthorizedToOrderAnimals = dlarAuthorizedToOrderAnimals;
					?'set isAuhtorizedToOrderAnimals => '+dlarAuthorizedToOrderAnimals+'\n';
					studyTeam.customAttributes.isInvolvedInAnimalHandling = dlarInvolvedInAnimalHandling;
					?'set isInvolvedInAnimalHandling => '+dlarInvolvedInAnimalHandling+'\n';

					protocolTeamMembers.addElement(studyTeam);
					?'added studyTeam to IACUC Study Team =>'+studyTeam+'\n';
				}
			{{/if}}

			/*
				1b. Assigning PI to Study
			*/
			//assigning PI to Study(IACUCQ)
			{{#if investigator.studyTeamMember.userId}}
				var investigator = iacucQ.getQualifiedAttribute("customAttributes._attribute7");

				var person = ApplicationEntity.getResultSet("Person").query("userID = '{{investigator.studyTeamMember.userId}}'").elements();
					
				if(investigator == null && person.count() > 0){
					person = person.item(1);
					iacucQ.setQualifiedAttribute("customAttributes._attribute7", person);
					?'person adding as PI =>'+person.userID+'\n';
				}
			{{/if}}

			/*
				1c. update contact for department admins
			*/
			contactSet = iacucQ.contacts;
			var deptAdmin = iacucQ.customAttributes.departmentAdministrators;
			for(var i = 1; i<= deptAdmin.count(); i++){
				var personToAdd = deptAdmin.elements().item(i);
				contactSet.addElement(personToAdd);
				?'added dept admin to contact set => '+personToAdd+'\n';

			}

			/*
				approval/annual expiration date
			*/

			{{#if approvalDate}}
				var date = "{{approvalDate}}";
				var dateArray = date.split('-');
				var day = dateArray[2].substring(0,2);
				var month = dateArray[1] - 1;
				var year = dateArray[0];
				var a = new Date(year, month, day);
				iacucQ.setQualifiedAttribute("customAttributes._attribute6", a);
				?'iacucQ.customAttributes._attribute6(Date Approved) =>'+a+'\n';
			{{/if}}

			/*
			** 07-20-2015 => Sandy => DLAR wants the annual expiration date
				{{#if finalExpirationDate}}
					var date = "{{finalExpirationDate}}";
					var dateArray = date.split('-');
					var day = dateArray[2].substring(0,2);
					var month = dateArray[1] - 1;
					var year = dateArray[0];
					var a = new Date(year, month, day);
					iacucQ.customAttributes._attribute10 = a;
					?'iacucQ.customAttributes._attribute10(Date Expiration) =>'+a+'\n';
				{{/if}}
			*/

			{{#if annualExpirationDate}}
				var date = "{{annualExpirationDate}}";
				var dateArray = date.split('-');
				var day = dateArray[2].substring(0,2);
				var month = dateArray[1] - 1;
				var year = dateArray[0];
				var a = new Date(year, month, day);
				iacucQ.customAttributes._attribute10 = a;
				?'iacucQ.customAttributes._attribute10(Date Expiration) =>'+a+'\n';
			{{/if}}

			/*
				updating species
			*/

				var animalCount = 0;

	{{#each animalCounts}}
		animalCount += {{actualNumberOfAnimals}};
	{{/each}}

	iacucQ.customAttributes._attribute71 = animalCount;
	?'setting total Number of animals for iacucQ=>'+animalCount+'\n';

	var painCategoryB = 'Pain Category B';
	var painCategoryC = 'Pain Category C';
	var painCategoryD = 'Pain Category D';
	var painCategoryE = 'Pain Category E';
	var animalGroupSet = iacucQ.customAttributes.SF_AnimalGroup;

	{{#each animalCounts}}
		var aCount = {{actualNumberOfAnimals}};

		if(aCount > 0){
			var animalGroupSet = iacucQ.customAttributes.SF_AnimalGroup;
			if(animalGroupSet == null){
				iacucQ.setQualifiedAttribute('customAttributes.SF_AnimalGroup',animalGroup)
				?'create eset iacucQ.customAttributes.SF_AnimalGroup=>'+animalGroup+'\n';
			}
			

			var species = "{{species.commonName}}";
			//species = species.replace(" ", "");
			var painCategory = "{{painCategory.category}}";
			var usda = "{{species.isUSDASpecies}}";
			var painCategory_1;

			if(painCategory == painCategoryB){
				painCategory_1 = "B";
			}
			else if(painCategory == painCategoryC){
				painCategory_1 = "C";
			}
			else if(painCategory == painCategoryD){
				painCategory_1 = "D";
			}
			else if(painCategory == painCategoryE){
				painCategory_1 = "E";
			}
			else{
				?'painCategoryNotFound=>'+painCategory+'\n';
			}

			if(painCategory_1 != null){
				var protoGroupName = species + ' {{painCategory.category}}';
				var exists = iacucQ.customAttributes.SF_AnimalGroup.query("customAttributes._ProtocolGroup.customAttributes._Species.customAttributes._attribute0='"+species+"'");
				if(usda == "yes" || usda == "Yes"){
					exists = exists.query("customAttributes._ProtocolGroup.customAttributes._Species.customAttributes.usdaCovered=true");
				}
				else{
					exists = exists.query("customAttributes._ProtocolGroup.customAttributes._Species.customAttributes.usdaCovered=false");
				}

				exists = exists.query("customAttributes._ProtocolGroup.customAttributes._ProtocolGroup='"+protoGroupName+"'");
				exists = exists.query("customAttributes._ProtocolGroup.customAttributes.usdaPainCategory.customAttributes.Category='"+painCategory_1+"'");
				?'Does Animal Exist in Set => '+exists.count()+'\n';

				if(exists.count() > 0){
					for(var i = 1; i<=exists.count(); i++){
						var newAnimalCount = {{actualNumberOfAnimals}};
						var item = exists.elements().item(i);
						var currentAnimalCount = item.customAttributes._ProtocolGroup.customAttributes.approved;
						var currentAnimalAvaliable = item.customAttributes._ProtocolGroup.customAttributes.available;
						var currentAnimalUsed = item.customAttributes._ProtocolGroup.customAttributes.used;
						var currentAnimalOnOrder = item.customAttributes._ProtocolGroup.customAttributes.onOrder;
						var totalOrderUsed = currentAnimalUsed+currentAnimalOnOrder;
						if(currentAnimalCount != newAnimalCount){
							?'Protocol Group => '+item+' count is different\n';
							item.customAttributes._ProtocolGroup.customAttributes.approved = newAnimalCount;
							?'setting new animal count => '+newAnimalCount+'\n';
						}

						if(currentAnimalAvaliable != newAnimalCount && totalOrderUsed < newAnimalCount){
							?'Protocol Group => '+item+' count is different and there is more animal avaliable\n';
							var newAvaliable = newAnimalCount - totalOrderUsed;
							item.customAttributes._ProtocolGroup.customAttributes.available = newAvaliable;
							?'setting new animal count(available) => '+newAvaliable+'\n';
						}
						else{
							?'Protocol Group => '+item+' count is different and there less animal avaliable\n';
							item.customAttributes._ProtocolGroup.customAttributes.available = 0;
							?'setting new animal count(available) => 0\n';	
						}
					}
				}
				else{
					?'Can't find animal in animal group =>'+species+'\n';
						var animalGroup = _IS_AnimalGroup.createEntity();
						var selAnimalGroup = _IS_SEL_AnimalGroup.createEntity();
						var clickPainCategory = ApplicationEntity.getResultSet('_ClickPainCategory').query("customAttributes.Category = '"+painCategory_1+"'");
						if(clickPainCategory.count() > 0){
							clickPainCategory = clickPainCategory.elements().item(1);
							selAnimalGroup.setQualifiedAttribute('customAttributes.usdaPainCategory', clickPainCategory);
							?'setting selAnimalGroup.customAttributes.usdaPainCategory =>'+clickPainCategory+'\n';
						}

						var clickSpecies = ApplicationEntity.getResultSet('_IACUC-Species').query("customAttributes._attribute0='"+species+"'");
						if(usda == "yes" || usda == "Yes"){
							clickSpecies = clickSpecies.query("customAttributes.usdaCovered=true");
						}
						else{
							clickSpecies = clickSpecies.query("customAttributes.usdaCovered=false");
						}
						if(clickSpecies.count() > 0){
							clickSpecies = clickSpecies.elements().item(1);
							selAnimalGroup.setQualifiedAttribute('customAttributes._Species', clickSpecies);
							speciesAdminSet.addElement(clickSpecies);
							?'adding clickSpeices to speciesAdminSet =>'+clickSpecies+'\n';
							?'setting selAnimalGroup.customAttributes._Species =>'+clickSpecies+'usda =>'+usda+'\n';
						}
						else{
							?'Cant find animal =>'+species+' usda =>'+usda+'\n';
						}
						selAnimalGroup.customAttributes.approved = {{actualNumberOfAnimals}};
						?'set number of approved for this animal =>{{actualNumberOfAnimals}}\n';

						var protoGroupName = species + ' {{painCategory.category}}';
						selAnimalGroup.customAttributes._ProtocolGroup = protoGroupName;
						?'set protocolGroup name =>'+protoGroupName+'\n';


						animalGroup.setQualifiedAttribute('customAttributes._ProtocolGroup', selAnimalGroup);
						animalGroupSet.addElement(animalGroup);
						?'adding eset animalGroupSet => '+animalGroup+'\n';
						groupAdminSet.addElement(selAnimalGroup);
						?'adding to eset groupAdminSet =>'+selAnimalGroup+'\n';
				}
			}
		}
	{{/each}}