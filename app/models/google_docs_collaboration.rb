#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

class GoogleDocsCollaboration < Collaboration
  include GoogleDocs
  
  def style_class
    'google_docs'
  end
  
  def service_name
    "Google Docs"
  end
  
  def delete_document
    if !self.document_id && self.user
      google_docs_delete_doc(GoogleDocEntry.new(self.data))
    end
  end
  
  def initialize_document
    if !self.document_id && self.user
      file = google_docs_create_doc(self.title)
      self.document_id = file.document_id
      self.data = file.entry.to_xml
      self.url = file.alternate_url.to_s
    end
  end
  
  def user_can_access_document_type?(user)
    if self.user && user
      google_services = user.user_services.find_all_by_service_domain("google.com").to_a
      !!google_services.find{|s| s.service_user_id}
    else
      false
    end
  end
  
  def authorize_user(user)
    return unless self.document_id
    google_services = user.user_services.find_all_by_service_domain("google.com").to_a
    service_user_id = google_services.find{|s| s.service_user_id}.service_user_id rescue nil
    collaborator = self.collaborators.find_by_user_id(user.id)
    if collaborator && collaborator.authorized_service_user_id != service_user_id
      google_docs_acl_remove(self.document_id, [collaborator.authorized_service_user_id]) if collaborator.authorized_service_user_id
      google_docs_acl_add(self.document_id, [user])
      collaborator.update_attributes(:authorized_service_user_id => service_user_id)
    end
  end
  
  def remove_users_from_document(users_to_remove)
    google_docs_acl_remove(self.document_id, users_to_remove) if self.document_id
  end
  
  def add_users_to_document(new_users)
    google_docs_acl_add(self.document_id, new_users) if self.document_id
  end
  
  def parse_data
    @entry_data ||= Atom::Entry.load_entry(self.data)
  end
  
  def self.config
    GoogleDocs.config
  end
end
