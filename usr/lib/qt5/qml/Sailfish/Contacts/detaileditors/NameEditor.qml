import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import org.nemomobile.contacts 1.0

BaseEditor {
    id: root

    property NicknameDetailModel nicknameModel
    property bool hasContent
    property var flickable

    // This editor shows name fields in this order: first name, nickname, middle name, last name.
    // Nicknames cannot be added from this editor, but are shown if they exist when the UI is
    // first shown. User can add nicknames from the 'Add details' InfoEditor.
    readonly property var _fields: [
        { "type": Person.FirstNameType, "propertyName": "firstName" },
        { "type": Person.NicknameType, "propertyName": "" },
        { "type": Person.MiddleNameType, "propertyName": "middleName" },
        { "type": Person.LastNameType, "propertyName": "lastName" }
    ]

    function populateFieldEditor() {
        detailModel.clear()

        for (var i = 0; i < root._fields.length; ++i) {
            var detail = root._fields[i]

            if (detail.type === Person.NicknameType) {
                for (var j = 0; j < nicknameModel.count; ++j) {
                    var nickname = nicknameModel.get(j)
                    detailModel.append(_nameProperties(Person.NicknameType, "", nickname.value, nickname.sourceIndex))
                }
                hasContent |= nicknameModel.count > 0
            } else {
                var value = contact[detail.propertyName]
                if (detail.type === Person.MiddleNameType
                        && value.length === 0) {
                    // If middle name is initially set, it is displayed here. Otherwise, it is added
                    // from the 'Add other detail' editor.
                    continue
                }

                detailModel.append(_nameProperties(detail.type, detail.propertyName, value, -1))
                hasContent |= value.length > 0
            }
        }
    }

    function aboutToSave() {
        // Ignore nickname changes, as those are handled in ContactDetailDialog.
        detailModel.copySingleTypeDetailChanges(contact, Person.NicknameType)
    }

    function _nameProperties(type, propertyName, value, sourceIndex) {
        var props = {
            "type": type,
            "subType": Person.NoSubType,
            "label": Person.NoLabel,
            "name": ContactsUtil.getNameForDetailType(type),
            "propertyName": propertyName,
            "value": value,
            "sourceIndex": sourceIndex
        }
        return props
    }

    fieldDelegate: EditorFieldDelegate {
        id: editorField

        editor: root
        leftMargin: 0

        onHasFocusChanged: {
            if (hasFocus) {
                // When moving from last editor field in the dialog back to the first field (i.e.
                // First Name) ensure the field is not hidden by the dialog header.
                root.flickable.contentY = 0
            }
        }

        onModified: {
            root.detailModel.setProperty(model.index, "value", value)
            if (model.type === Person.NicknameType) {
                var nicknameIndex = nicknameModel.findNicknameWithSourceIndex(model.sourceIndex)
                if (nicknameIndex >= 0) {
                    nicknameModel.userModified = true
                    nicknameModel.setProperty(nicknameIndex, "value", value)
                }
            }

            var _hasContent = value.length > 0
            if (!_hasContent) {
                for (var i = 0; i < detailModel.count; ++i) {
                    if (root.detailModel.get(i).value.length > 0) {
                        _hasContent = true
                        break
                    }
                }
            }
            root.hasContent = _hasContent
        }
    }
}
