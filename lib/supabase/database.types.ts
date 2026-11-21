export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18"
  }
  public: {
    Tables: {
      admin_audit_log: {
        Row: {
          action: string
          admin_id: string | null
          changes: Json | null
          created_at: string
          id: string
          resource_id: string | null
          resource_type: string | null
        }
        Insert: {
          action: string
          admin_id?: string | null
          changes?: Json | null
          created_at?: string
          id?: string
          resource_id?: string | null
          resource_type?: string | null
        }
        Update: {
          action?: string
          admin_id?: string | null
          changes?: Json | null
          created_at?: string
          id?: string
          resource_id?: string | null
          resource_type?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "admin_audit_log_admin_id_fkey"
            columns: ["admin_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_role_permissions: {
        Row: {
          access: string
          module: string
          role_id: string
        }
        Insert: {
          access?: string
          module: string
          role_id: string
        }
        Update: {
          access?: string
          module?: string
          role_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "admin_role_permissions_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "admin_roles"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_roles: {
        Row: {
          created_at: string
          description: string | null
          id: string
          name: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          name: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          name?: string
        }
        Relationships: []
      }
      admin_users: {
        Row: {
          created_at: string
          created_by: string | null
          mfa_enabled: boolean
          role_id: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          mfa_enabled?: boolean
          role_id: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          mfa_enabled?: boolean
          role_id?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "admin_users_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_users_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "admin_roles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_users_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      album_media: {
        Row: {
          album_id: string
          caption: string | null
          country_code: string
          created_at: string
          duration_ms: number | null
          height: number | null
          id: string
          kind: string
          owner_id: string
          path: string
          size_bytes: number | null
          sort_order: number
          taken_at: string | null
          thumbnail_path: string | null
          width: number | null
        }
        Insert: {
          album_id: string
          caption?: string | null
          country_code?: string
          created_at?: string
          duration_ms?: number | null
          height?: number | null
          id?: string
          kind: string
          owner_id: string
          path: string
          size_bytes?: number | null
          sort_order?: number
          taken_at?: string | null
          thumbnail_path?: string | null
          width?: number | null
        }
        Update: {
          album_id?: string
          caption?: string | null
          country_code?: string
          created_at?: string
          duration_ms?: number | null
          height?: number | null
          id?: string
          kind?: string
          owner_id?: string
          path?: string
          size_bytes?: number | null
          sort_order?: number
          taken_at?: string | null
          thumbnail_path?: string | null
          width?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "album_media_album_id_fkey"
            columns: ["album_id"]
            isOneToOne: false
            referencedRelation: "albums"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "album_media_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      albums: {
        Row: {
          country_code: string
          cover_media_id: string | null
          cover_path: string | null
          created_at: string
          description: string | null
          id: string
          item_count: number
          owner_id: string
          title: string
          updated_at: string
          visibility: string
        }
        Insert: {
          country_code?: string
          cover_media_id?: string | null
          cover_path?: string | null
          created_at?: string
          description?: string | null
          id?: string
          item_count?: number
          owner_id: string
          title: string
          updated_at?: string
          visibility?: string
        }
        Update: {
          country_code?: string
          cover_media_id?: string | null
          cover_path?: string | null
          created_at?: string
          description?: string | null
          id?: string
          item_count?: number
          owner_id?: string
          title?: string
          updated_at?: string
          visibility?: string
        }
        Relationships: [
          {
            foreignKeyName: "albums_cover_media_fkey"
            columns: ["cover_media_id"]
            isOneToOne: false
            referencedRelation: "album_media"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "albums_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      banned_words: {
        Row: {
          country_code: string | null
          created_at: string
          created_by: string | null
          id: string
          severity: string
          word: string
        }
        Insert: {
          country_code?: string | null
          created_at?: string
          created_by?: string | null
          id?: string
          severity?: string
          word: string
        }
        Update: {
          country_code?: string | null
          created_at?: string
          created_by?: string | null
          id?: string
          severity?: string
          word?: string
        }
        Relationships: [
          {
            foreignKeyName: "banned_words_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "banned_words_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      billing_customers: {
        Row: {
          created_at: string
          stripe_customer_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          stripe_customer_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          stripe_customer_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "billing_customers_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      blocks: {
        Row: {
          blocked_id: string
          blocker_id: string
          created_at: string
          id: string
        }
        Insert: {
          blocked_id: string
          blocker_id: string
          created_at?: string
          id?: string
        }
        Update: {
          blocked_id?: string
          blocker_id?: string
          created_at?: string
          id?: string
        }
        Relationships: [
          {
            foreignKeyName: "blocks_blocked_id_fkey"
            columns: ["blocked_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "blocks_blocker_id_fkey"
            columns: ["blocker_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      calendar_rules: {
        Row: {
          allowed_days: number[] | null
          applies_to: string | null
          bag_limit: number | null
          bag_period: string | null
          calendar_id: string
          created_at: string
          date_from: string | null
          date_to: string | null
          id: string
          kind: string
          notes: string | null
          sort_order: number
          time_rule: string | null
        }
        Insert: {
          allowed_days?: number[] | null
          applies_to?: string | null
          bag_limit?: number | null
          bag_period?: string | null
          calendar_id: string
          created_at?: string
          date_from?: string | null
          date_to?: string | null
          id?: string
          kind: string
          notes?: string | null
          sort_order?: number
          time_rule?: string | null
        }
        Update: {
          allowed_days?: number[] | null
          applies_to?: string | null
          bag_limit?: number | null
          bag_period?: string | null
          calendar_id?: string
          created_at?: string
          date_from?: string | null
          date_to?: string | null
          id?: string
          kind?: string
          notes?: string | null
          sort_order?: number
          time_rule?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "calendar_rules_calendar_id_fkey"
            columns: ["calendar_id"]
            isOneToOne: false
            referencedRelation: "hunting_calendars"
            referencedColumns: ["id"]
          },
        ]
      }
      categories: {
        Row: {
          created_at: string
          id: string
          is_restricted: boolean
          kind: string
          name_key: string
          parent_id: string | null
          slug: string
          sort_order: number
        }
        Insert: {
          created_at?: string
          id?: string
          is_restricted?: boolean
          kind: string
          name_key: string
          parent_id?: string | null
          slug: string
          sort_order?: number
        }
        Update: {
          created_at?: string
          id?: string
          is_restricted?: boolean
          kind?: string
          name_key?: string
          parent_id?: string | null
          slug?: string
          sort_order?: number
        }
        Relationships: [
          {
            foreignKeyName: "categories_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
        ]
      }
      comment_likes: {
        Row: {
          comment_id: string
          created_at: string
          user_id: string
        }
        Insert: {
          comment_id: string
          created_at?: string
          user_id: string
        }
        Update: {
          comment_id?: string
          created_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "comment_likes_comment_id_fkey"
            columns: ["comment_id"]
            isOneToOne: false
            referencedRelation: "comments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comment_likes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      comments: {
        Row: {
          author_id: string
          content: string
          created_at: string
          id: string
          parent_id: string | null
          post_id: string
          reaction_count: number
          reply_count: number
          status: string
          updated_at: string
        }
        Insert: {
          author_id: string
          content: string
          created_at?: string
          id?: string
          parent_id?: string | null
          post_id: string
          reaction_count?: number
          reply_count?: number
          status?: string
          updated_at?: string
        }
        Update: {
          author_id?: string
          content?: string
          created_at?: string
          id?: string
          parent_id?: string | null
          post_id?: string
          reaction_count?: number
          reply_count?: number
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "comments_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "comments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
        ]
      }
      conversation_participants: {
        Row: {
          conversation_id: string
          created_at: string
          id: string
          last_read_at: string | null
          muted_until: string | null
          role: string
          user_id: string
        }
        Insert: {
          conversation_id: string
          created_at?: string
          id?: string
          last_read_at?: string | null
          muted_until?: string | null
          role?: string
          user_id: string
        }
        Update: {
          conversation_id?: string
          created_at?: string
          id?: string
          last_read_at?: string | null
          muted_until?: string | null
          role?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "conversation_participants_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conversation_participants_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      conversations: {
        Row: {
          created_at: string
          created_by: string
          id: string
          kind: string
          last_message_at: string | null
          title: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          created_by: string
          id?: string
          kind?: string
          last_message_at?: string | null
          title?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          created_by?: string
          id?: string
          kind?: string
          last_message_at?: string | null
          title?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "conversations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      countries: {
        Row: {
          code: string
          created_at: string
          default_currency: string
          default_locale: string
          is_active: boolean
          name: string
          season_start_month: number
          sort_order: number
          timezone: string
          unit_system: string
        }
        Insert: {
          code: string
          created_at?: string
          default_currency: string
          default_locale?: string
          is_active?: boolean
          name: string
          season_start_month?: number
          sort_order?: number
          timezone?: string
          unit_system?: string
        }
        Update: {
          code?: string
          created_at?: string
          default_currency?: string
          default_locale?: string
          is_active?: boolean
          name?: string
          season_start_month?: number
          sort_order?: number
          timezone?: string
          unit_system?: string
        }
        Relationships: [
          {
            foreignKeyName: "countries_default_currency_fkey"
            columns: ["default_currency"]
            isOneToOne: false
            referencedRelation: "currencies"
            referencedColumns: ["code"]
          },
        ]
      }
      country_policies: {
        Row: {
          country_code: string
          created_at: string
          id: string
          policy_data: Json
          policy_type: string
          updated_at: string
        }
        Insert: {
          country_code: string
          created_at?: string
          id?: string
          policy_data?: Json
          policy_type: string
          updated_at?: string
        }
        Update: {
          country_code?: string
          created_at?: string
          id?: string
          policy_data?: Json
          policy_type?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "country_policies_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
        ]
      }
      currencies: {
        Row: {
          code: string
          created_at: string
          is_active: boolean
          minor_units: number
          name: string
          symbol: string
        }
        Insert: {
          code: string
          created_at?: string
          is_active?: boolean
          minor_units?: number
          name: string
          symbol: string
        }
        Update: {
          code?: string
          created_at?: string
          is_active?: boolean
          minor_units?: number
          name?: string
          symbol?: string
        }
        Relationships: []
      }
      dog_breeds: {
        Row: {
          created_at: string
          fci_group: number | null
          id: string
          names: Json
          origin: string | null
          slug: string
          sort_order: number
          work_type: string
        }
        Insert: {
          created_at?: string
          fci_group?: number | null
          id?: string
          names: Json
          origin?: string | null
          slug: string
          sort_order?: number
          work_type: string
        }
        Update: {
          created_at?: string
          fci_group?: number | null
          id?: string
          names?: Json
          origin?: string | null
          slug?: string
          sort_order?: number
          work_type?: string
        }
        Relationships: []
      }
      dog_health_records: {
        Row: {
          created_at: string
          dog_id: string
          due_on: string | null
          id: string
          kind: string
          notes: string | null
          owner_id: string
          performed_on: string
          title: string
          updated_at: string
          vet_name: string | null
        }
        Insert: {
          created_at?: string
          dog_id: string
          due_on?: string | null
          id?: string
          kind: string
          notes?: string | null
          owner_id: string
          performed_on: string
          title: string
          updated_at?: string
          vet_name?: string | null
        }
        Update: {
          created_at?: string
          dog_id?: string
          due_on?: string | null
          id?: string
          kind?: string
          notes?: string | null
          owner_id?: string
          performed_on?: string
          title?: string
          updated_at?: string
          vet_name?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "dog_health_records_dog_id_fkey"
            columns: ["dog_id"]
            isOneToOne: false
            referencedRelation: "dogs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "dog_health_records_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      dog_trials: {
        Row: {
          certificate_path: string | null
          country_code: string
          created_at: string
          dog_id: string
          event_id: string | null
          id: string
          judge: string | null
          kind: string
          notes: string | null
          organizer: string | null
          owner_id: string
          place: string | null
          points: string | null
          result: string | null
          title: string
          trial_date: string
          updated_at: string
        }
        Insert: {
          certificate_path?: string | null
          country_code?: string
          created_at?: string
          dog_id: string
          event_id?: string | null
          id?: string
          judge?: string | null
          kind: string
          notes?: string | null
          organizer?: string | null
          owner_id: string
          place?: string | null
          points?: string | null
          result?: string | null
          title: string
          trial_date: string
          updated_at?: string
        }
        Update: {
          certificate_path?: string | null
          country_code?: string
          created_at?: string
          dog_id?: string
          event_id?: string | null
          id?: string
          judge?: string | null
          kind?: string
          notes?: string | null
          organizer?: string | null
          owner_id?: string
          place?: string | null
          points?: string | null
          result?: string | null
          title?: string
          trial_date?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "dog_trials_dog_id_fkey"
            columns: ["dog_id"]
            isOneToOne: false
            referencedRelation: "dogs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "dog_trials_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "dog_trials_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      dogs: {
        Row: {
          avatar_url: string | null
          birth_date: string | null
          breed: string | null
          breed_id: string | null
          breeder_page_id: string | null
          color: string | null
          country_code: string
          cover_url: string | null
          created_at: string
          deceased_on: string | null
          description: string | null
          father_name: string | null
          harvest_total: number
          id: string
          kennel_name: string | null
          microchip_number: string | null
          mother_name: string | null
          name: string
          outing_count: number
          owner_id: string
          pedigree_number: string | null
          post_count: number
          sex: string | null
          status: string
          trial_count: number
          updated_at: string
          visibility: string
          weight_kg: number | null
        }
        Insert: {
          avatar_url?: string | null
          birth_date?: string | null
          breed?: string | null
          breed_id?: string | null
          breeder_page_id?: string | null
          color?: string | null
          country_code?: string
          cover_url?: string | null
          created_at?: string
          deceased_on?: string | null
          description?: string | null
          father_name?: string | null
          harvest_total?: number
          id?: string
          kennel_name?: string | null
          microchip_number?: string | null
          mother_name?: string | null
          name: string
          outing_count?: number
          owner_id: string
          pedigree_number?: string | null
          post_count?: number
          sex?: string | null
          status?: string
          trial_count?: number
          updated_at?: string
          visibility?: string
          weight_kg?: number | null
        }
        Update: {
          avatar_url?: string | null
          birth_date?: string | null
          breed?: string | null
          breed_id?: string | null
          breeder_page_id?: string | null
          color?: string | null
          country_code?: string
          cover_url?: string | null
          created_at?: string
          deceased_on?: string | null
          description?: string | null
          father_name?: string | null
          harvest_total?: number
          id?: string
          kennel_name?: string | null
          microchip_number?: string | null
          mother_name?: string | null
          name?: string
          outing_count?: number
          owner_id?: string
          pedigree_number?: string | null
          post_count?: number
          sex?: string | null
          status?: string
          trial_count?: number
          updated_at?: string
          visibility?: string
          weight_kg?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "dogs_breed_id_fkey"
            columns: ["breed_id"]
            isOneToOne: false
            referencedRelation: "dog_breeds"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "dogs_breeder_page_id_fkey"
            columns: ["breeder_page_id"]
            isOneToOne: false
            referencedRelation: "pages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "dogs_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      event_participants: {
        Row: {
          checked_in_at: string | null
          checked_in_by: string | null
          created_at: string
          event_id: string
          id: string
          paid_at: string | null
          payment_method: string | null
          payment_status: string
          status: string
          ticket_code: string | null
          updated_at: string
          user_id: string
          waitlisted_at: string | null
        }
        Insert: {
          checked_in_at?: string | null
          checked_in_by?: string | null
          created_at?: string
          event_id: string
          id?: string
          paid_at?: string | null
          payment_method?: string | null
          payment_status?: string
          status?: string
          ticket_code?: string | null
          updated_at?: string
          user_id: string
          waitlisted_at?: string | null
        }
        Update: {
          checked_in_at?: string | null
          checked_in_by?: string | null
          created_at?: string
          event_id?: string
          id?: string
          paid_at?: string | null
          payment_method?: string | null
          payment_status?: string
          status?: string
          ticket_code?: string | null
          updated_at?: string
          user_id?: string
          waitlisted_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "event_participants_checked_in_by_fkey"
            columns: ["checked_in_by"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "event_participants_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "event_participants_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      events: {
        Row: {
          address: string | null
          attendee_count: number
          capacity: number | null
          category: string
          country_code: string
          cover_url: string | null
          created_at: string
          created_by: string
          currency_code: string
          description: string | null
          ends_at: string | null
          hunting_unit_id: string | null
          id: string
          interested_count: number
          lat: number | null
          lng: number | null
          location_name: string | null
          organizer_group_id: string | null
          organizer_page_id: string | null
          organizer_user_id: string | null
          price_minor: number
          region_id: string | null
          search_tsv: unknown
          starts_at: string
          status: string
          title: string
          updated_at: string
        }
        Insert: {
          address?: string | null
          attendee_count?: number
          capacity?: number | null
          category: string
          country_code?: string
          cover_url?: string | null
          created_at?: string
          created_by: string
          currency_code?: string
          description?: string | null
          ends_at?: string | null
          hunting_unit_id?: string | null
          id?: string
          interested_count?: number
          lat?: number | null
          lng?: number | null
          location_name?: string | null
          organizer_group_id?: string | null
          organizer_page_id?: string | null
          organizer_user_id?: string | null
          price_minor?: number
          region_id?: string | null
          search_tsv?: unknown
          starts_at: string
          status?: string
          title: string
          updated_at?: string
        }
        Update: {
          address?: string | null
          attendee_count?: number
          capacity?: number | null
          category?: string
          country_code?: string
          cover_url?: string | null
          created_at?: string
          created_by?: string
          currency_code?: string
          description?: string | null
          ends_at?: string | null
          hunting_unit_id?: string | null
          id?: string
          interested_count?: number
          lat?: number | null
          lng?: number | null
          location_name?: string | null
          organizer_group_id?: string | null
          organizer_page_id?: string | null
          organizer_user_id?: string | null
          price_minor?: number
          region_id?: string | null
          search_tsv?: unknown
          starts_at?: string
          status?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "events_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "events_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_currency_code_fkey"
            columns: ["currency_code"]
            isOneToOne: false
            referencedRelation: "currencies"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "events_hunting_unit_id_fkey"
            columns: ["hunting_unit_id"]
            isOneToOne: false
            referencedRelation: "hunting_units"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_organizer_group_id_fkey"
            columns: ["organizer_group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_organizer_page_id_fkey"
            columns: ["organizer_page_id"]
            isOneToOne: false
            referencedRelation: "pages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_organizer_user_id_fkey"
            columns: ["organizer_user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_region_id_fkey"
            columns: ["region_id"]
            isOneToOne: false
            referencedRelation: "regions"
            referencedColumns: ["id"]
          },
        ]
      }
      exchange_rates: {
        Row: {
          base_code: string
          created_at: string
          id: string
          quote_code: string
          rate: number
          source: string | null
          valid_on: string
        }
        Insert: {
          base_code: string
          created_at?: string
          id?: string
          quote_code: string
          rate: number
          source?: string | null
          valid_on: string
        }
        Update: {
          base_code?: string
          created_at?: string
          id?: string
          quote_code?: string
          rate?: number
          source?: string | null
          valid_on?: string
        }
        Relationships: [
          {
            foreignKeyName: "exchange_rates_base_code_fkey"
            columns: ["base_code"]
            isOneToOne: false
            referencedRelation: "currencies"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "exchange_rates_quote_code_fkey"
            columns: ["quote_code"]
            isOneToOne: false
            referencedRelation: "currencies"
            referencedColumns: ["code"]
          },
        ]
      }
      feature_flags: {
        Row: {
          country_code: string | null
          created_at: string
          description: string | null
          id: string
          is_enabled: boolean
          module: string
          rollout_percentage: number
          updated_at: string
        }
        Insert: {
          country_code?: string | null
          created_at?: string
          description?: string | null
          id?: string
          is_enabled?: boolean
          module: string
          rollout_percentage?: number
          updated_at?: string
        }
        Update: {
          country_code?: string | null
          created_at?: string
          description?: string | null
          id?: string
          is_enabled?: boolean
          module?: string
          rollout_percentage?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "feature_flags_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
        ]
      }
      follows: {
        Row: {
          created_at: string
          follower_id: string
          following_id: string
          id: string
        }
        Insert: {
          created_at?: string
          follower_id: string
          following_id: string
          id?: string
        }
        Update: {
          created_at?: string
          follower_id?: string
          following_id?: string
          id?: string
        }
        Relationships: [
          {
            foreignKeyName: "follows_follower_id_fkey"
            columns: ["follower_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "follows_following_id_fkey"
            columns: ["following_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      forum_attachments: {
        Row: {
          country_code: string
          created_at: string
          duration_ms: number | null
          file_name: string | null
          height: number | null
          id: string
          kind: string
          mime_type: string | null
          path: string
          reply_id: string | null
          size_bytes: number | null
          sort_order: number
          thread_id: string | null
          thumbnail_path: string | null
          width: number | null
        }
        Insert: {
          country_code?: string
          created_at?: string
          duration_ms?: number | null
          file_name?: string | null
          height?: number | null
          id?: string
          kind: string
          mime_type?: string | null
          path: string
          reply_id?: string | null
          size_bytes?: number | null
          sort_order?: number
          thread_id?: string | null
          thumbnail_path?: string | null
          width?: number | null
        }
        Update: {
          country_code?: string
          created_at?: string
          duration_ms?: number | null
          file_name?: string | null
          height?: number | null
          id?: string
          kind?: string
          mime_type?: string | null
          path?: string
          reply_id?: string | null
          size_bytes?: number | null
          sort_order?: number
          thread_id?: string | null
          thumbnail_path?: string | null
          width?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "forum_attachments_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "forum_attachments_reply_id_fkey"
            columns: ["reply_id"]
            isOneToOne: false
            referencedRelation: "forum_replies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "forum_attachments_thread_id_fkey"
            columns: ["thread_id"]
            isOneToOne: false
            referencedRelation: "forum_threads"
            referencedColumns: ["id"]
          },
        ]
      }
      forum_members: {
        Row: {
          ban_reason: string | null
          banned_at: string | null
          banned_by: string | null
          created_at: string
          forum_id: string
          id: string
          role: string
          status: string
          user_id: string
        }
        Insert: {
          ban_reason?: string | null
          banned_at?: string | null
          banned_by?: string | null
          created_at?: string
          forum_id: string
          id?: string
          role?: string
          status?: string
          user_id: string
        }
        Update: {
          ban_reason?: string | null
          banned_at?: string | null
          banned_by?: string | null
          created_at?: string
          forum_id?: string
          id?: string
          role?: string
          status?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "forum_members_banned_by_fkey"
            columns: ["banned_by"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "forum_members_forum_id_fkey"
            columns: ["forum_id"]
            isOneToOne: false
            referencedRelation: "forums"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "forum_members_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      forum_replies: {
        Row: {
          author_id: string
          content: string
          created_at: string
          id: string
          parent_id: string | null
          reaction_count: number
          status: string
          thread_id: string
          updated_at: string
        }
        Insert: {
          author_id: string
          content: string
          created_at?: string
          id?: string
          parent_id?: string | null
          reaction_count?: number
          status?: string
          thread_id: string
          updated_at?: string
        }
        Update: {
          author_id?: string
          content?: string
          created_at?: string
          id?: string
          parent_id?: string | null
          reaction_count?: number
          status?: string
          thread_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "forum_replies_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "forum_replies_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "forum_replies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "forum_replies_thread_id_fkey"
            columns: ["thread_id"]
            isOneToOne: false
            referencedRelation: "forum_threads"
            referencedColumns: ["id"]
          },
        ]
      }
      forum_reply_likes: {
        Row: {
          created_at: string
          reply_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          reply_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          reply_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "forum_reply_likes_reply_id_fkey"
            columns: ["reply_id"]
            isOneToOne: false
            referencedRelation: "forum_replies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "forum_reply_likes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      forum_thread_subscriptions: {
        Row: {
          created_at: string
          thread_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          thread_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          thread_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "forum_thread_subscriptions_thread_id_fkey"
            columns: ["thread_id"]
            isOneToOne: false
            referencedRelation: "forum_threads"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "forum_thread_subscriptions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      forum_thread_tags: {
        Row: {
          created_at: string
          hashtag_id: string
          thread_id: string
        }
        Insert: {
          created_at?: string
          hashtag_id: string
          thread_id: string
        }
        Update: {
          created_at?: string
          hashtag_id?: string
          thread_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "forum_thread_tags_hashtag_id_fkey"
            columns: ["hashtag_id"]
            isOneToOne: false
            referencedRelation: "hashtags"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "forum_thread_tags_thread_id_fkey"
            columns: ["thread_id"]
            isOneToOne: false
            referencedRelation: "forum_threads"
            referencedColumns: ["id"]
          },
        ]
      }
      forum_thread_views_daily: {
        Row: {
          day: string
          thread_id: string
          views: number
        }
        Insert: {
          day: string
          thread_id: string
          views?: number
        }
        Update: {
          day?: string
          thread_id?: string
          views?: number
        }
        Relationships: [
          {
            foreignKeyName: "forum_thread_views_daily_thread_id_fkey"
            columns: ["thread_id"]
            isOneToOne: false
            referencedRelation: "forum_threads"
            referencedColumns: ["id"]
          },
        ]
      }
      forum_threads: {
        Row: {
          author_id: string
          content: string | null
          country_code: string
          created_at: string
          forum_id: string
          id: string
          is_locked: boolean
          is_pinned: boolean
          last_reply_at: string | null
          reply_count: number
          search_tsv: unknown
          solution_reply_id: string | null
          status: string
          title: string
          updated_at: string
          view_count: number
        }
        Insert: {
          author_id: string
          content?: string | null
          country_code?: string
          created_at?: string
          forum_id: string
          id?: string
          is_locked?: boolean
          is_pinned?: boolean
          last_reply_at?: string | null
          reply_count?: number
          search_tsv?: unknown
          solution_reply_id?: string | null
          status?: string
          title: string
          updated_at?: string
          view_count?: number
        }
        Update: {
          author_id?: string
          content?: string | null
          country_code?: string
          created_at?: string
          forum_id?: string
          id?: string
          is_locked?: boolean
          is_pinned?: boolean
          last_reply_at?: string | null
          reply_count?: number
          search_tsv?: unknown
          solution_reply_id?: string | null
          status?: string
          title?: string
          updated_at?: string
          view_count?: number
        }
        Relationships: [
          {
            foreignKeyName: "forum_threads_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "forum_threads_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "forum_threads_forum_id_fkey"
            columns: ["forum_id"]
            isOneToOne: false
            referencedRelation: "forums"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "forum_threads_solution_reply_fk"
            columns: ["solution_reply_id"]
            isOneToOne: false
            referencedRelation: "forum_replies"
            referencedColumns: ["id"]
          },
        ]
      }
      forums: {
        Row: {
          avatar_url: string | null
          category: string | null
          country_code: string
          cover_url: string | null
          created_at: string
          description: string | null
          id: string
          member_count: number
          name: string
          owner_id: string
          search_tsv: unknown
          slug: string
          status: string
          thread_count: number
          updated_at: string
          visibility: string
        }
        Insert: {
          avatar_url?: string | null
          category?: string | null
          country_code?: string
          cover_url?: string | null
          created_at?: string
          description?: string | null
          id?: string
          member_count?: number
          name: string
          owner_id: string
          search_tsv?: unknown
          slug: string
          status?: string
          thread_count?: number
          updated_at?: string
          visibility?: string
        }
        Update: {
          avatar_url?: string | null
          category?: string | null
          country_code?: string
          cover_url?: string | null
          created_at?: string
          description?: string | null
          id?: string
          member_count?: number
          name?: string
          owner_id?: string
          search_tsv?: unknown
          slug?: string
          status?: string
          thread_count?: number
          updated_at?: string
          visibility?: string
        }
        Relationships: [
          {
            foreignKeyName: "forums_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "forums_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      friend_requests: {
        Row: {
          addressee_id: string
          created_at: string
          id: string
          message: string | null
          requester_id: string
          responded_at: string | null
          status: string
        }
        Insert: {
          addressee_id: string
          created_at?: string
          id?: string
          message?: string | null
          requester_id: string
          responded_at?: string | null
          status?: string
        }
        Update: {
          addressee_id?: string
          created_at?: string
          id?: string
          message?: string | null
          requester_id?: string
          responded_at?: string | null
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "friend_requests_addressee_id_fkey"
            columns: ["addressee_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "friend_requests_requester_id_fkey"
            columns: ["requester_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      friendships: {
        Row: {
          created_at: string
          user_a: string
          user_b: string
        }
        Insert: {
          created_at?: string
          user_a: string
          user_b: string
        }
        Update: {
          created_at?: string
          user_a?: string
          user_b?: string
        }
        Relationships: [
          {
            foreignKeyName: "friendships_user_a_fkey"
            columns: ["user_a"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "friendships_user_b_fkey"
            columns: ["user_b"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      group_members: {
        Row: {
          ban_reason: string | null
          banned_at: string | null
          banned_by: string | null
          created_at: string
          group_id: string
          id: string
          role: string
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          ban_reason?: string | null
          banned_at?: string | null
          banned_by?: string | null
          created_at?: string
          group_id: string
          id?: string
          role?: string
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          ban_reason?: string | null
          banned_at?: string | null
          banned_by?: string | null
          created_at?: string
          group_id?: string
          id?: string
          role?: string
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "group_members_banned_by_fkey"
            columns: ["banned_by"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "group_members_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "group_members_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      groups: {
        Row: {
          avatar_url: string | null
          category: string | null
          country_code: string
          cover_url: string | null
          created_at: string
          description: string | null
          id: string
          join_policy: string
          member_count: number
          name: string
          owner_id: string
          post_count: number
          region_id: string | null
          search_tsv: unknown
          slug: string
          status: string
          updated_at: string
          visibility: string
        }
        Insert: {
          avatar_url?: string | null
          category?: string | null
          country_code?: string
          cover_url?: string | null
          created_at?: string
          description?: string | null
          id?: string
          join_policy?: string
          member_count?: number
          name: string
          owner_id: string
          post_count?: number
          region_id?: string | null
          search_tsv?: unknown
          slug: string
          status?: string
          updated_at?: string
          visibility?: string
        }
        Update: {
          avatar_url?: string | null
          category?: string | null
          country_code?: string
          cover_url?: string | null
          created_at?: string
          description?: string | null
          id?: string
          join_policy?: string
          member_count?: number
          name?: string
          owner_id?: string
          post_count?: number
          region_id?: string | null
          search_tsv?: unknown
          slug?: string
          status?: string
          updated_at?: string
          visibility?: string
        }
        Relationships: [
          {
            foreignKeyName: "groups_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "groups_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "groups_region_id_fkey"
            columns: ["region_id"]
            isOneToOne: false
            referencedRelation: "regions"
            referencedColumns: ["id"]
          },
        ]
      }
      hashtags: {
        Row: {
          created_at: string
          id: string
          post_count: number
          search_tsv: unknown
          tag: string
          thread_count: number
        }
        Insert: {
          created_at?: string
          id?: string
          post_count?: number
          search_tsv?: unknown
          tag: string
          thread_count?: number
        }
        Update: {
          created_at?: string
          id?: string
          post_count?: number
          search_tsv?: unknown
          tag?: string
          thread_count?: number
        }
        Relationships: []
      }
      hidden_posts: {
        Row: {
          created_at: string
          post_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          post_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          post_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "hidden_posts_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hidden_posts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      hunting_calendars: {
        Row: {
          country_code: string
          created_at: string
          hunting_unit_id: string | null
          id: string
          notes: string | null
          published_at: string | null
          published_by: string | null
          region_id: string
          season_label: string
          source_name: string | null
          source_url: string | null
          species_id: string
          status: string
          updated_at: string
          valid_from: string
          valid_to: string
        }
        Insert: {
          country_code: string
          created_at?: string
          hunting_unit_id?: string | null
          id?: string
          notes?: string | null
          published_at?: string | null
          published_by?: string | null
          region_id: string
          season_label: string
          source_name?: string | null
          source_url?: string | null
          species_id: string
          status?: string
          updated_at?: string
          valid_from: string
          valid_to: string
        }
        Update: {
          country_code?: string
          created_at?: string
          hunting_unit_id?: string | null
          id?: string
          notes?: string | null
          published_at?: string | null
          published_by?: string | null
          region_id?: string
          season_label?: string
          source_name?: string | null
          source_url?: string | null
          species_id?: string
          status?: string
          updated_at?: string
          valid_from?: string
          valid_to?: string
        }
        Relationships: [
          {
            foreignKeyName: "hunting_calendars_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "hunting_calendars_hunting_unit_id_fkey"
            columns: ["hunting_unit_id"]
            isOneToOne: false
            referencedRelation: "hunting_units"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hunting_calendars_published_by_fkey"
            columns: ["published_by"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hunting_calendars_region_id_fkey"
            columns: ["region_id"]
            isOneToOne: false
            referencedRelation: "regions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hunting_calendars_species_id_fkey"
            columns: ["species_id"]
            isOneToOne: false
            referencedRelation: "species"
            referencedColumns: ["id"]
          },
        ]
      }
      hunting_log_dogs: {
        Row: {
          created_at: string
          dog_id: string
          log_id: string
        }
        Insert: {
          created_at?: string
          dog_id: string
          log_id: string
        }
        Update: {
          created_at?: string
          dog_id?: string
          log_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "hunting_log_dogs_dog_id_fkey"
            columns: ["dog_id"]
            isOneToOne: false
            referencedRelation: "dogs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hunting_log_dogs_log_id_fkey"
            columns: ["log_id"]
            isOneToOne: false
            referencedRelation: "hunting_logs"
            referencedColumns: ["id"]
          },
        ]
      }
      hunting_log_media: {
        Row: {
          caption: string | null
          country_code: string
          created_at: string
          duration_ms: number | null
          height: number | null
          id: string
          kind: string
          log_id: string
          owner_id: string
          path: string
          size_bytes: number | null
          sort_order: number
          thumbnail_path: string | null
          width: number | null
        }
        Insert: {
          caption?: string | null
          country_code?: string
          created_at?: string
          duration_ms?: number | null
          height?: number | null
          id?: string
          kind: string
          log_id: string
          owner_id: string
          path: string
          size_bytes?: number | null
          sort_order?: number
          thumbnail_path?: string | null
          width?: number | null
        }
        Update: {
          caption?: string | null
          country_code?: string
          created_at?: string
          duration_ms?: number | null
          height?: number | null
          id?: string
          kind?: string
          log_id?: string
          owner_id?: string
          path?: string
          size_bytes?: number | null
          sort_order?: number
          thumbnail_path?: string | null
          width?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "hunting_log_media_log_id_fkey"
            columns: ["log_id"]
            isOneToOne: false
            referencedRelation: "hunting_logs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hunting_log_media_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      hunting_log_points: {
        Row: {
          accuracy_m: number | null
          created_at: string
          lat: number
          lng: number
          log_id: string
        }
        Insert: {
          accuracy_m?: number | null
          created_at?: string
          lat: number
          lng: number
          log_id: string
        }
        Update: {
          accuracy_m?: number | null
          created_at?: string
          lat?: number
          lng?: number
          log_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "hunting_log_points_log_id_fkey"
            columns: ["log_id"]
            isOneToOne: true
            referencedRelation: "hunting_logs"
            referencedColumns: ["id"]
          },
        ]
      }
      hunting_log_species: {
        Row: {
          created_at: string
          harvest_count: number
          id: string
          log_id: string
          notes: string | null
          seen_count: number
          shots: number
          species_id: string
        }
        Insert: {
          created_at?: string
          harvest_count?: number
          id?: string
          log_id: string
          notes?: string | null
          seen_count?: number
          shots?: number
          species_id: string
        }
        Update: {
          created_at?: string
          harvest_count?: number
          id?: string
          log_id?: string
          notes?: string | null
          seen_count?: number
          shots?: number
          species_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "hunting_log_species_log_id_fkey"
            columns: ["log_id"]
            isOneToOne: false
            referencedRelation: "hunting_logs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hunting_log_species_species_id_fkey"
            columns: ["species_id"]
            isOneToOne: false
            referencedRelation: "species"
            referencedColumns: ["id"]
          },
        ]
      }
      hunting_logs: {
        Row: {
          country_code: string
          created_at: string
          distance_m: number | null
          ended_at: string | null
          harvest_total: number
          hunting_method: string | null
          hunting_unit_id: string | null
          id: string
          media_count: number
          municipality_id: string | null
          notes: string | null
          region_id: string | null
          started_at: string
          title: string | null
          updated_at: string
          user_id: string
          visibility: string
          weather: Json
          zone_name: string | null
        }
        Insert: {
          country_code?: string
          created_at?: string
          distance_m?: number | null
          ended_at?: string | null
          harvest_total?: number
          hunting_method?: string | null
          hunting_unit_id?: string | null
          id?: string
          media_count?: number
          municipality_id?: string | null
          notes?: string | null
          region_id?: string | null
          started_at: string
          title?: string | null
          updated_at?: string
          user_id: string
          visibility?: string
          weather?: Json
          zone_name?: string | null
        }
        Update: {
          country_code?: string
          created_at?: string
          distance_m?: number | null
          ended_at?: string | null
          harvest_total?: number
          hunting_method?: string | null
          hunting_unit_id?: string | null
          id?: string
          media_count?: number
          municipality_id?: string | null
          notes?: string | null
          region_id?: string | null
          started_at?: string
          title?: string | null
          updated_at?: string
          user_id?: string
          visibility?: string
          weather?: Json
          zone_name?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "hunting_logs_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "hunting_logs_hunting_unit_id_fkey"
            columns: ["hunting_unit_id"]
            isOneToOne: false
            referencedRelation: "hunting_units"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hunting_logs_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hunting_logs_region_id_fkey"
            columns: ["region_id"]
            isOneToOne: false
            referencedRelation: "regions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hunting_logs_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      hunting_unit_areas: {
        Row: {
          area_m2: number | null
          created_at: string
          geojson: Json
          max_lat: number | null
          max_lng: number | null
          min_lat: number | null
          min_lng: number | null
          source: string | null
          unit_id: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          area_m2?: number | null
          created_at?: string
          geojson: Json
          max_lat?: number | null
          max_lng?: number | null
          min_lat?: number | null
          min_lng?: number | null
          source?: string | null
          unit_id: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          area_m2?: number | null
          created_at?: string
          geojson?: Json
          max_lat?: number | null
          max_lng?: number | null
          min_lat?: number | null
          min_lng?: number | null
          source?: string | null
          unit_id?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "hunting_unit_areas_unit_id_fkey"
            columns: ["unit_id"]
            isOneToOne: true
            referencedRelation: "hunting_units"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hunting_unit_areas_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      hunting_unit_types: {
        Row: {
          code: string
          country_code: string
          created_at: string
          name_key: string
          sort_order: number
        }
        Insert: {
          code: string
          country_code: string
          created_at?: string
          name_key: string
          sort_order?: number
        }
        Update: {
          code?: string
          country_code?: string
          created_at?: string
          name_key?: string
          sort_order?: number
        }
        Relationships: [
          {
            foreignKeyName: "hunting_unit_types_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
        ]
      }
      hunting_units: {
        Row: {
          code: string | null
          country_code: string
          created_at: string
          id: string
          municipality_id: string | null
          name: string
          notes: string | null
          region_id: string | null
          unit_type: string
          updated_at: string
          website: string | null
        }
        Insert: {
          code?: string | null
          country_code: string
          created_at?: string
          id?: string
          municipality_id?: string | null
          name: string
          notes?: string | null
          region_id?: string | null
          unit_type: string
          updated_at?: string
          website?: string | null
        }
        Update: {
          code?: string | null
          country_code?: string
          created_at?: string
          id?: string
          municipality_id?: string | null
          name?: string
          notes?: string | null
          region_id?: string | null
          unit_type?: string
          updated_at?: string
          website?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "hunting_units_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "hunting_units_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hunting_units_region_id_fkey"
            columns: ["region_id"]
            isOneToOne: false
            referencedRelation: "regions"
            referencedColumns: ["id"]
          },
        ]
      }
      listing_contacts: {
        Row: {
          badge_level_at_contact: string | null
          conversation_id: string | null
          created_at: string
          listing_id: string
          user_id: string
        }
        Insert: {
          badge_level_at_contact?: string | null
          conversation_id?: string | null
          created_at?: string
          listing_id: string
          user_id: string
        }
        Update: {
          badge_level_at_contact?: string | null
          conversation_id?: string | null
          created_at?: string
          listing_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "listing_contacts_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "listing_contacts_listing_id_fkey"
            columns: ["listing_id"]
            isOneToOne: false
            referencedRelation: "listings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "listing_contacts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      listing_favorites: {
        Row: {
          created_at: string
          listing_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          listing_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          listing_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "listing_favorites_listing_id_fkey"
            columns: ["listing_id"]
            isOneToOne: false
            referencedRelation: "listings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "listing_favorites_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      listing_media: {
        Row: {
          created_at: string
          id: string
          listing_id: string
          path: string
          sort_order: number
        }
        Insert: {
          created_at?: string
          id?: string
          listing_id: string
          path: string
          sort_order?: number
        }
        Update: {
          created_at?: string
          id?: string
          listing_id?: string
          path?: string
          sort_order?: number
        }
        Relationships: [
          {
            foreignKeyName: "listing_media_listing_id_fkey"
            columns: ["listing_id"]
            isOneToOne: false
            referencedRelation: "listings"
            referencedColumns: ["id"]
          },
        ]
      }
      listing_views: {
        Row: {
          created_at: string
          listing_id: string
          user_id: string
          viewed_on: string
        }
        Insert: {
          created_at?: string
          listing_id: string
          user_id: string
          viewed_on?: string
        }
        Update: {
          created_at?: string
          listing_id?: string
          user_id?: string
          viewed_on?: string
        }
        Relationships: [
          {
            foreignKeyName: "listing_views_listing_id_fkey"
            columns: ["listing_id"]
            isOneToOne: false
            referencedRelation: "listings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "listing_views_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      listings: {
        Row: {
          attributes: Json
          category_id: string
          condition: string
          contact_count: number
          country_code: string
          created_at: string
          currency_code: string
          description: string | null
          expires_at: string | null
          favorite_count: number
          id: string
          is_mediated: boolean
          lat: number | null
          lng: number | null
          media_count: number
          municipality: string | null
          municipality_id: string | null
          negotiable: boolean
          page_id: string | null
          price_minor: number
          region_id: string | null
          reserved_at: string | null
          search_tsv: unknown
          seller_id: string
          shipping_available: boolean
          sold_at: string | null
          status: string
          title: string
          updated_at: string
          view_count: number
        }
        Insert: {
          attributes?: Json
          category_id: string
          condition?: string
          contact_count?: number
          country_code?: string
          created_at?: string
          currency_code?: string
          description?: string | null
          expires_at?: string | null
          favorite_count?: number
          id?: string
          is_mediated?: boolean
          lat?: number | null
          lng?: number | null
          media_count?: number
          municipality?: string | null
          municipality_id?: string | null
          negotiable?: boolean
          page_id?: string | null
          price_minor: number
          region_id?: string | null
          reserved_at?: string | null
          search_tsv?: unknown
          seller_id: string
          shipping_available?: boolean
          sold_at?: string | null
          status?: string
          title: string
          updated_at?: string
          view_count?: number
        }
        Update: {
          attributes?: Json
          category_id?: string
          condition?: string
          contact_count?: number
          country_code?: string
          created_at?: string
          currency_code?: string
          description?: string | null
          expires_at?: string | null
          favorite_count?: number
          id?: string
          is_mediated?: boolean
          lat?: number | null
          lng?: number | null
          media_count?: number
          municipality?: string | null
          municipality_id?: string | null
          negotiable?: boolean
          page_id?: string | null
          price_minor?: number
          region_id?: string | null
          reserved_at?: string | null
          search_tsv?: unknown
          seller_id?: string
          shipping_available?: boolean
          sold_at?: string | null
          status?: string
          title?: string
          updated_at?: string
          view_count?: number
        }
        Relationships: [
          {
            foreignKeyName: "listings_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "listings_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "listings_currency_code_fkey"
            columns: ["currency_code"]
            isOneToOne: false
            referencedRelation: "currencies"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "listings_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "listings_page_id_fkey"
            columns: ["page_id"]
            isOneToOne: false
            referencedRelation: "pages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "listings_region_id_fkey"
            columns: ["region_id"]
            isOneToOne: false
            referencedRelation: "regions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "listings_seller_id_fkey"
            columns: ["seller_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      map_points: {
        Row: {
          color: string | null
          country_code: string
          created_at: string
          hunting_unit_id: string | null
          id: string
          kind: string
          lat: number
          lng: number
          name: string
          notes: string | null
          updated_at: string
          user_id: string
          visibility: string
        }
        Insert: {
          color?: string | null
          country_code?: string
          created_at?: string
          hunting_unit_id?: string | null
          id?: string
          kind?: string
          lat: number
          lng: number
          name: string
          notes?: string | null
          updated_at?: string
          user_id: string
          visibility?: string
        }
        Update: {
          color?: string | null
          country_code?: string
          created_at?: string
          hunting_unit_id?: string | null
          id?: string
          kind?: string
          lat?: number
          lng?: number
          name?: string
          notes?: string | null
          updated_at?: string
          user_id?: string
          visibility?: string
        }
        Relationships: [
          {
            foreignKeyName: "map_points_hunting_unit_id_fkey"
            columns: ["hunting_unit_id"]
            isOneToOne: false
            referencedRelation: "hunting_units"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "map_points_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      map_zones: {
        Row: {
          area_m2: number | null
          color: string | null
          country_code: string
          created_at: string
          geojson: Json
          id: string
          max_lat: number | null
          max_lng: number | null
          min_lat: number | null
          min_lng: number | null
          name: string
          notes: string | null
          updated_at: string
          user_id: string
          visibility: string
        }
        Insert: {
          area_m2?: number | null
          color?: string | null
          country_code?: string
          created_at?: string
          geojson: Json
          id?: string
          max_lat?: number | null
          max_lng?: number | null
          min_lat?: number | null
          min_lng?: number | null
          name: string
          notes?: string | null
          updated_at?: string
          user_id: string
          visibility?: string
        }
        Update: {
          area_m2?: number | null
          color?: string | null
          country_code?: string
          created_at?: string
          geojson?: Json
          id?: string
          max_lat?: number | null
          max_lng?: number | null
          min_lat?: number | null
          min_lng?: number | null
          name?: string
          notes?: string | null
          updated_at?: string
          user_id?: string
          visibility?: string
        }
        Relationships: [
          {
            foreignKeyName: "map_zones_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      messages: {
        Row: {
          body: string | null
          client_id: string | null
          conversation_id: string
          created_at: string
          duration_ms: number | null
          id: string
          kind: string
          media_height: number | null
          media_mime: string | null
          media_path: string | null
          media_size: number | null
          media_width: number | null
          meta: Json | null
          reply_to_id: string | null
          sender_id: string
          status: string
          updated_at: string
        }
        Insert: {
          body?: string | null
          client_id?: string | null
          conversation_id: string
          created_at?: string
          duration_ms?: number | null
          id?: string
          kind?: string
          media_height?: number | null
          media_mime?: string | null
          media_path?: string | null
          media_size?: number | null
          media_width?: number | null
          meta?: Json | null
          reply_to_id?: string | null
          sender_id: string
          status?: string
          updated_at?: string
        }
        Update: {
          body?: string | null
          client_id?: string | null
          conversation_id?: string
          created_at?: string
          duration_ms?: number | null
          id?: string
          kind?: string
          media_height?: number | null
          media_mime?: string | null
          media_path?: string | null
          media_size?: number | null
          media_width?: number | null
          meta?: Json | null
          reply_to_id?: string | null
          sender_id?: string
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "messages_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "messages_reply_to_id_fkey"
            columns: ["reply_to_id"]
            isOneToOne: false
            referencedRelation: "messages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "messages_sender_id_fkey"
            columns: ["sender_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      municipalities: {
        Row: {
          cadastral_code: string | null
          country_code: string
          created_at: string
          id: string
          is_active: boolean
          istat_code: string
          lat: number | null
          lng: number | null
          name: string
          name_alt: string | null
          name_search: string
          population: number | null
          province_code: string
          province_istat: string | null
          province_name: string | null
          region_id: string
          updated_at: string
        }
        Insert: {
          cadastral_code?: string | null
          country_code?: string
          created_at?: string
          id?: string
          is_active?: boolean
          istat_code: string
          lat?: number | null
          lng?: number | null
          name: string
          name_alt?: string | null
          name_search?: string
          population?: number | null
          province_code: string
          province_istat?: string | null
          province_name?: string | null
          region_id: string
          updated_at?: string
        }
        Update: {
          cadastral_code?: string | null
          country_code?: string
          created_at?: string
          id?: string
          is_active?: boolean
          istat_code?: string
          lat?: number | null
          lng?: number | null
          name?: string
          name_alt?: string | null
          name_search?: string
          population?: number | null
          province_code?: string
          province_istat?: string | null
          province_name?: string | null
          region_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "municipalities_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "municipalities_region_id_fkey"
            columns: ["region_id"]
            isOneToOne: false
            referencedRelation: "regions"
            referencedColumns: ["id"]
          },
        ]
      }
      mutes: {
        Row: {
          created_at: string
          muted_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          muted_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          muted_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "mutes_muted_id_fkey"
            columns: ["muted_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "mutes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          actor_id: string | null
          created_at: string
          data: Json
          id: string
          kind: string
          push_sent_at: string | null
          read_at: string | null
          target_id: string | null
          target_type: string | null
          user_id: string
        }
        Insert: {
          actor_id?: string | null
          created_at?: string
          data?: Json
          id?: string
          kind: string
          push_sent_at?: string | null
          read_at?: string | null
          target_id?: string | null
          target_type?: string | null
          user_id: string
        }
        Update: {
          actor_id?: string | null
          created_at?: string
          data?: Json
          id?: string
          kind?: string
          push_sent_at?: string | null
          read_at?: string | null
          target_id?: string | null
          target_type?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_actor_id_fkey"
            columns: ["actor_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      order_events: {
        Row: {
          actor_id: string | null
          created_at: string
          data: Json
          id: string
          kind: string
          order_id: string
        }
        Insert: {
          actor_id?: string | null
          created_at?: string
          data?: Json
          id?: string
          kind: string
          order_id: string
        }
        Update: {
          actor_id?: string | null
          created_at?: string
          data?: Json
          id?: string
          kind?: string
          order_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "order_events_actor_id_fkey"
            columns: ["actor_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_events_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      orders: {
        Row: {
          amount_minor: number
          buyer_id: string
          buyer_note: string | null
          cancel_reason: string | null
          cancelled_at: string | null
          completed_at: string | null
          country_code: string
          created_at: string
          currency_code: string
          delivery_method: string
          dispute_status: string | null
          event_id: string | null
          expires_at: string | null
          id: string
          kind: string
          listing_id: string | null
          paid_at: string | null
          participant_id: string | null
          platform_fee_minor: number
          refund_reason: string | null
          refunded_at: string | null
          seller_id: string
          seller_payout_minor: number
          shipped_at: string | null
          shipping_address: Json | null
          shipping_minor: number
          status: string
          status_before_dispute: string | null
          stripe_charge_id: string | null
          stripe_checkout_session_id: string | null
          stripe_dispute_id: string | null
          stripe_payment_intent_id: string | null
          stripe_refund_id: string | null
          title: string
          total_minor: number
          tracking_carrier: string | null
          tracking_code: string | null
          updated_at: string
        }
        Insert: {
          amount_minor: number
          buyer_id: string
          buyer_note?: string | null
          cancel_reason?: string | null
          cancelled_at?: string | null
          completed_at?: string | null
          country_code?: string
          created_at?: string
          currency_code: string
          delivery_method?: string
          dispute_status?: string | null
          event_id?: string | null
          expires_at?: string | null
          id?: string
          kind?: string
          listing_id?: string | null
          paid_at?: string | null
          participant_id?: string | null
          platform_fee_minor?: number
          refund_reason?: string | null
          refunded_at?: string | null
          seller_id: string
          seller_payout_minor: number
          shipped_at?: string | null
          shipping_address?: Json | null
          shipping_minor?: number
          status?: string
          status_before_dispute?: string | null
          stripe_charge_id?: string | null
          stripe_checkout_session_id?: string | null
          stripe_dispute_id?: string | null
          stripe_payment_intent_id?: string | null
          stripe_refund_id?: string | null
          title: string
          total_minor: number
          tracking_carrier?: string | null
          tracking_code?: string | null
          updated_at?: string
        }
        Update: {
          amount_minor?: number
          buyer_id?: string
          buyer_note?: string | null
          cancel_reason?: string | null
          cancelled_at?: string | null
          completed_at?: string | null
          country_code?: string
          created_at?: string
          currency_code?: string
          delivery_method?: string
          dispute_status?: string | null
          event_id?: string | null
          expires_at?: string | null
          id?: string
          kind?: string
          listing_id?: string | null
          paid_at?: string | null
          participant_id?: string | null
          platform_fee_minor?: number
          refund_reason?: string | null
          refunded_at?: string | null
          seller_id?: string
          seller_payout_minor?: number
          shipped_at?: string | null
          shipping_address?: Json | null
          shipping_minor?: number
          status?: string
          status_before_dispute?: string | null
          stripe_charge_id?: string | null
          stripe_checkout_session_id?: string | null
          stripe_dispute_id?: string | null
          stripe_payment_intent_id?: string | null
          stripe_refund_id?: string | null
          title?: string
          total_minor?: number
          tracking_carrier?: string | null
          tracking_code?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "orders_buyer_id_fkey"
            columns: ["buyer_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_currency_code_fkey"
            columns: ["currency_code"]
            isOneToOne: false
            referencedRelation: "currencies"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "orders_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_listing_id_fkey"
            columns: ["listing_id"]
            isOneToOne: false
            referencedRelation: "listings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_participant_id_fkey"
            columns: ["participant_id"]
            isOneToOne: false
            referencedRelation: "event_participants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_seller_id_fkey"
            columns: ["seller_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      page_followers: {
        Row: {
          created_at: string
          id: string
          page_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          page_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          page_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "page_followers_page_id_fkey"
            columns: ["page_id"]
            isOneToOne: false
            referencedRelation: "pages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "page_followers_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      page_roles: {
        Row: {
          created_at: string
          id: string
          page_id: string
          role: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          page_id: string
          role?: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          page_id?: string
          role?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "page_roles_page_id_fkey"
            columns: ["page_id"]
            isOneToOne: false
            referencedRelation: "pages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "page_roles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      pages: {
        Row: {
          address: string | null
          avatar_url: string | null
          category: string
          country_code: string
          cover_url: string | null
          created_at: string
          description: string | null
          email: string | null
          follower_count: number
          id: string
          name: string
          owner_id: string
          phone: string | null
          post_count: number
          region_id: string | null
          search_tsv: unknown
          slug: string
          status: string
          updated_at: string
          verification_status: string
          verified_at: string | null
          website: string | null
        }
        Insert: {
          address?: string | null
          avatar_url?: string | null
          category: string
          country_code?: string
          cover_url?: string | null
          created_at?: string
          description?: string | null
          email?: string | null
          follower_count?: number
          id?: string
          name: string
          owner_id: string
          phone?: string | null
          post_count?: number
          region_id?: string | null
          search_tsv?: unknown
          slug: string
          status?: string
          updated_at?: string
          verification_status?: string
          verified_at?: string | null
          website?: string | null
        }
        Update: {
          address?: string | null
          avatar_url?: string | null
          category?: string
          country_code?: string
          cover_url?: string | null
          created_at?: string
          description?: string | null
          email?: string | null
          follower_count?: number
          id?: string
          name?: string
          owner_id?: string
          phone?: string | null
          post_count?: number
          region_id?: string | null
          search_tsv?: unknown
          slug?: string
          status?: string
          updated_at?: string
          verification_status?: string
          verified_at?: string | null
          website?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "pages_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "pages_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "pages_region_id_fkey"
            columns: ["region_id"]
            isOneToOne: false
            referencedRelation: "regions"
            referencedColumns: ["id"]
          },
        ]
      }
      payment_methods: {
        Row: {
          brand: string | null
          country_code: string | null
          created_at: string
          exp_month: number | null
          exp_year: number | null
          failure_count: number
          id: string
          is_default: boolean
          last_failed_at: string | null
          last_failure_code: string | null
          last4: string | null
          status: string
          stripe_payment_method_id: string
          type: string
          updated_at: string
          user_id: string
        }
        Insert: {
          brand?: string | null
          country_code?: string | null
          created_at?: string
          exp_month?: number | null
          exp_year?: number | null
          failure_count?: number
          id?: string
          is_default?: boolean
          last_failed_at?: string | null
          last_failure_code?: string | null
          last4?: string | null
          status?: string
          stripe_payment_method_id: string
          type?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          brand?: string | null
          country_code?: string | null
          created_at?: string
          exp_month?: number | null
          exp_year?: number | null
          failure_count?: number
          id?: string
          is_default?: boolean
          last_failed_at?: string | null
          last_failure_code?: string | null
          last4?: string | null
          status?: string
          stripe_payment_method_id?: string
          type?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "payment_methods_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      platform_settings: {
        Row: {
          created_at: string
          key: string
          updated_at: string
          updated_by: string | null
          value: Json
        }
        Insert: {
          created_at?: string
          key: string
          updated_at?: string
          updated_by?: string | null
          value?: Json
        }
        Update: {
          created_at?: string
          key?: string
          updated_at?: string
          updated_by?: string | null
          value?: Json
        }
        Relationships: [
          {
            foreignKeyName: "platform_settings_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      poll_options: {
        Row: {
          created_at: string
          id: string
          label: string
          poll_id: string
          sort_order: number
          vote_count: number
        }
        Insert: {
          created_at?: string
          id?: string
          label: string
          poll_id: string
          sort_order?: number
          vote_count?: number
        }
        Update: {
          created_at?: string
          id?: string
          label?: string
          poll_id?: string
          sort_order?: number
          vote_count?: number
        }
        Relationships: [
          {
            foreignKeyName: "poll_options_poll_id_fkey"
            columns: ["poll_id"]
            isOneToOne: false
            referencedRelation: "polls"
            referencedColumns: ["id"]
          },
        ]
      }
      poll_votes: {
        Row: {
          created_at: string
          option_id: string
          poll_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          option_id: string
          poll_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          option_id?: string
          poll_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "poll_votes_option_id_fkey"
            columns: ["option_id"]
            isOneToOne: false
            referencedRelation: "poll_options"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "poll_votes_poll_id_fkey"
            columns: ["poll_id"]
            isOneToOne: false
            referencedRelation: "polls"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "poll_votes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      polls: {
        Row: {
          allow_multiple: boolean
          created_at: string
          ends_at: string | null
          id: string
          post_id: string
          question: string | null
          total_votes: number
        }
        Insert: {
          allow_multiple?: boolean
          created_at?: string
          ends_at?: string | null
          id?: string
          post_id: string
          question?: string | null
          total_votes?: number
        }
        Update: {
          allow_multiple?: boolean
          created_at?: string
          ends_at?: string | null
          id?: string
          post_id?: string
          question?: string | null
          total_votes?: number
        }
        Relationships: [
          {
            foreignKeyName: "polls_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
        ]
      }
      post_dogs: {
        Row: {
          created_at: string
          dog_id: string
          post_id: string
        }
        Insert: {
          created_at?: string
          dog_id: string
          post_id: string
        }
        Update: {
          created_at?: string
          dog_id?: string
          post_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "post_dogs_dog_id_fkey"
            columns: ["dog_id"]
            isOneToOne: false
            referencedRelation: "dogs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_dogs_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
        ]
      }
      post_hashtags: {
        Row: {
          created_at: string
          hashtag_id: string
          post_id: string
        }
        Insert: {
          created_at?: string
          hashtag_id: string
          post_id: string
        }
        Update: {
          created_at?: string
          hashtag_id?: string
          post_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "post_hashtags_hashtag_id_fkey"
            columns: ["hashtag_id"]
            isOneToOne: false
            referencedRelation: "hashtags"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_hashtags_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
        ]
      }
      post_media: {
        Row: {
          created_at: string
          duration_ms: number | null
          height: number | null
          id: string
          kind: string
          path: string
          post_id: string
          sort_order: number
          thumbnail_path: string | null
          width: number | null
        }
        Insert: {
          created_at?: string
          duration_ms?: number | null
          height?: number | null
          id?: string
          kind: string
          path: string
          post_id: string
          sort_order?: number
          thumbnail_path?: string | null
          width?: number | null
        }
        Update: {
          created_at?: string
          duration_ms?: number | null
          height?: number | null
          id?: string
          kind?: string
          path?: string
          post_id?: string
          sort_order?: number
          thumbnail_path?: string | null
          width?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "post_media_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
        ]
      }
      post_mentions: {
        Row: {
          created_at: string
          post_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          post_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          post_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "post_mentions_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_mentions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      posts: {
        Row: {
          author_id: string
          comment_count: number
          content: string | null
          country_code: string
          created_at: string
          group_id: string | null
          hunting_unit_id: string | null
          id: string
          is_sensitive: boolean
          kind: string
          lat: number | null
          lng: number | null
          location_name: string | null
          page_id: string | null
          reaction_count: number
          search_tsv: unknown
          share_count: number
          shared_post_id: string | null
          status: string
          updated_at: string
          visibility: string
          shared_post: {
            author_id: string
            comment_count: number
            content: string | null
            country_code: string
            created_at: string
            group_id: string | null
            hunting_unit_id: string | null
            id: string
            is_sensitive: boolean
            kind: string
            lat: number | null
            lng: number | null
            location_name: string | null
            page_id: string | null
            reaction_count: number
            search_tsv: unknown
            share_count: number
            shared_post_id: string | null
            status: string
            updated_at: string
            visibility: string
          } | null
        }
        Insert: {
          author_id: string
          comment_count?: number
          content?: string | null
          country_code?: string
          created_at?: string
          group_id?: string | null
          hunting_unit_id?: string | null
          id?: string
          is_sensitive?: boolean
          kind?: string
          lat?: number | null
          lng?: number | null
          location_name?: string | null
          page_id?: string | null
          reaction_count?: number
          search_tsv?: unknown
          share_count?: number
          shared_post_id?: string | null
          status?: string
          updated_at?: string
          visibility?: string
        }
        Update: {
          author_id?: string
          comment_count?: number
          content?: string | null
          country_code?: string
          created_at?: string
          group_id?: string | null
          hunting_unit_id?: string | null
          id?: string
          is_sensitive?: boolean
          kind?: string
          lat?: number | null
          lng?: number | null
          location_name?: string | null
          page_id?: string | null
          reaction_count?: number
          search_tsv?: unknown
          share_count?: number
          shared_post_id?: string | null
          status?: string
          updated_at?: string
          visibility?: string
        }
        Relationships: [
          {
            foreignKeyName: "posts_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "posts_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "posts_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "posts_hunting_unit_id_fkey"
            columns: ["hunting_unit_id"]
            isOneToOne: false
            referencedRelation: "hunting_units"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "posts_page_id_fkey"
            columns: ["page_id"]
            isOneToOne: false
            referencedRelation: "pages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "posts_shared_post_id_fkey"
            columns: ["shared_post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
        ]
      }
      push_tokens: {
        Row: {
          created_at: string
          id: string
          last_used_at: string | null
          platform: string
          token: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          last_used_at?: string | null
          platform: string
          token: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          last_used_at?: string | null
          platform?: string
          token?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "push_tokens_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      reactions: {
        Row: {
          created_at: string
          id: string
          post_id: string
          reaction_type: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          post_id: string
          reaction_type?: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          post_id?: string
          reaction_type?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "reactions_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reactions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      regions: {
        Row: {
          code: string
          country_code: string
          created_at: string
          id: string
          istat_code: string | null
          kind: string
          lat: number | null
          lng: number | null
          name: string
          sort_order: number
        }
        Insert: {
          code: string
          country_code: string
          created_at?: string
          id?: string
          istat_code?: string | null
          kind?: string
          lat?: number | null
          lng?: number | null
          name: string
          sort_order?: number
        }
        Update: {
          code?: string
          country_code?: string
          created_at?: string
          id?: string
          istat_code?: string | null
          kind?: string
          lat?: number | null
          lng?: number | null
          name?: string
          sort_order?: number
        }
        Relationships: [
          {
            foreignKeyName: "regions_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
        ]
      }
      reports: {
        Row: {
          assigned_to: string | null
          country_code: string
          created_at: string
          details: string | null
          id: string
          priority: string
          reason: string
          reporter_id: string | null
          resolution: string | null
          resolved_at: string | null
          status: string
          target_author_id: string | null
          target_id: string
          target_type: string
          updated_at: string
        }
        Insert: {
          assigned_to?: string | null
          country_code?: string
          created_at?: string
          details?: string | null
          id?: string
          priority?: string
          reason: string
          reporter_id?: string | null
          resolution?: string | null
          resolved_at?: string | null
          status?: string
          target_author_id?: string | null
          target_id: string
          target_type: string
          updated_at?: string
        }
        Update: {
          assigned_to?: string | null
          country_code?: string
          created_at?: string
          details?: string | null
          id?: string
          priority?: string
          reason?: string
          reporter_id?: string | null
          resolution?: string | null
          resolved_at?: string | null
          status?: string
          target_author_id?: string | null
          target_id?: string
          target_type?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "reports_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reports_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "reports_reporter_id_fkey"
            columns: ["reporter_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reports_target_author_id_fkey"
            columns: ["target_author_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      seller_accounts: {
        Row: {
          charges_enabled: boolean
          country_code: string
          created_at: string
          default_currency: string
          details_submitted: boolean
          last_synced_at: string | null
          onboarding_status: string
          payouts_enabled: boolean
          requirements: Json
          stripe_account_id: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          charges_enabled?: boolean
          country_code?: string
          created_at?: string
          default_currency?: string
          details_submitted?: boolean
          last_synced_at?: string | null
          onboarding_status?: string
          payouts_enabled?: boolean
          requirements?: Json
          stripe_account_id?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          charges_enabled?: boolean
          country_code?: string
          created_at?: string
          default_currency?: string
          details_submitted?: boolean
          last_synced_at?: string | null
          onboarding_status?: string
          payouts_enabled?: boolean
          requirements?: Json
          stripe_account_id?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "seller_accounts_default_currency_fkey"
            columns: ["default_currency"]
            isOneToOne: false
            referencedRelation: "currencies"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "seller_accounts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      seller_reviews: {
        Row: {
          comment: string | null
          country_code: string
          created_at: string
          id: string
          listing_id: string
          rating: number
          reply: string | null
          reply_at: string | null
          reviewer_id: string
          seller_id: string
          status: string
          updated_at: string
        }
        Insert: {
          comment?: string | null
          country_code?: string
          created_at?: string
          id?: string
          listing_id: string
          rating: number
          reply?: string | null
          reply_at?: string | null
          reviewer_id: string
          seller_id: string
          status?: string
          updated_at?: string
        }
        Update: {
          comment?: string | null
          country_code?: string
          created_at?: string
          id?: string
          listing_id?: string
          rating?: number
          reply?: string | null
          reply_at?: string | null
          reviewer_id?: string
          seller_id?: string
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "seller_reviews_listing_id_fkey"
            columns: ["listing_id"]
            isOneToOne: false
            referencedRelation: "listings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "seller_reviews_reviewer_id_fkey"
            columns: ["reviewer_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "seller_reviews_seller_id_fkey"
            columns: ["seller_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      sighting_alerts: {
        Row: {
          cooldown_min: number
          country_code: string
          created_at: string
          fire_count: number
          id: string
          is_active: boolean
          kinds: string[]
          last_fired_at: string | null
          lat: number | null
          lng: number | null
          min_animals: number
          municipality_id: string | null
          name: string
          radius_km: number | null
          region_id: string | null
          species_id: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          cooldown_min?: number
          country_code?: string
          created_at?: string
          fire_count?: number
          id?: string
          is_active?: boolean
          kinds?: string[]
          last_fired_at?: string | null
          lat?: number | null
          lng?: number | null
          min_animals?: number
          municipality_id?: string | null
          name: string
          radius_km?: number | null
          region_id?: string | null
          species_id?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          cooldown_min?: number
          country_code?: string
          created_at?: string
          fire_count?: number
          id?: string
          is_active?: boolean
          kinds?: string[]
          last_fired_at?: string | null
          lat?: number | null
          lng?: number | null
          min_animals?: number
          municipality_id?: string | null
          name?: string
          radius_km?: number | null
          region_id?: string | null
          species_id?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "sighting_alerts_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sighting_alerts_region_id_fkey"
            columns: ["region_id"]
            isOneToOne: false
            referencedRelation: "regions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sighting_alerts_species_id_fkey"
            columns: ["species_id"]
            isOneToOne: false
            referencedRelation: "species"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sighting_alerts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      sightings: {
        Row: {
          accuracy_m: number | null
          animals_count: number
          cell_lat: number | null
          cell_lng: number | null
          country_code: string
          created_at: string
          hunting_unit_id: string | null
          id: string
          kind: string
          lat: number | null
          lng: number | null
          log_id: string | null
          media_path: string | null
          municipality_id: string | null
          notes: string | null
          region_id: string | null
          sighted_at: string
          species_id: string
          thumbnail_path: string | null
          updated_at: string
          user_id: string
          visibility: string
        }
        Insert: {
          accuracy_m?: number | null
          animals_count?: number
          cell_lat?: number | null
          cell_lng?: number | null
          country_code?: string
          created_at?: string
          hunting_unit_id?: string | null
          id?: string
          kind?: string
          lat?: number | null
          lng?: number | null
          log_id?: string | null
          media_path?: string | null
          municipality_id?: string | null
          notes?: string | null
          region_id?: string | null
          sighted_at: string
          species_id: string
          thumbnail_path?: string | null
          updated_at?: string
          user_id: string
          visibility?: string
        }
        Update: {
          accuracy_m?: number | null
          animals_count?: number
          cell_lat?: number | null
          cell_lng?: number | null
          country_code?: string
          created_at?: string
          hunting_unit_id?: string | null
          id?: string
          kind?: string
          lat?: number | null
          lng?: number | null
          log_id?: string | null
          media_path?: string | null
          municipality_id?: string | null
          notes?: string | null
          region_id?: string | null
          sighted_at?: string
          species_id?: string
          thumbnail_path?: string | null
          updated_at?: string
          user_id?: string
          visibility?: string
        }
        Relationships: [
          {
            foreignKeyName: "sightings_hunting_unit_id_fkey"
            columns: ["hunting_unit_id"]
            isOneToOne: false
            referencedRelation: "hunting_units"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sightings_log_id_fkey"
            columns: ["log_id"]
            isOneToOne: false
            referencedRelation: "hunting_logs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sightings_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sightings_region_id_fkey"
            columns: ["region_id"]
            isOneToOne: false
            referencedRelation: "regions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sightings_species_id_fkey"
            columns: ["species_id"]
            isOneToOne: false
            referencedRelation: "species"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sightings_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      species: {
        Row: {
          category: string
          created_at: string
          id: string
          scientific_name: string
        }
        Insert: {
          category?: string
          created_at?: string
          id?: string
          scientific_name: string
        }
        Update: {
          category?: string
          created_at?: string
          id?: string
          scientific_name?: string
        }
        Relationships: []
      }
      species_names: {
        Row: {
          created_at: string
          id: string
          locale: string
          name: string
          species_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          locale: string
          name: string
          species_id: string
        }
        Update: {
          created_at?: string
          id?: string
          locale?: string
          name?: string
          species_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "species_names_species_id_fkey"
            columns: ["species_id"]
            isOneToOne: false
            referencedRelation: "species"
            referencedColumns: ["id"]
          },
        ]
      }
      stories: {
        Row: {
          author_id: string
          caption: string | null
          country_code: string
          created_at: string
          expires_at: string
          id: string
          kind: string
          media_path: string
          status: string
          thumbnail_path: string | null
          view_count: number
        }
        Insert: {
          author_id: string
          caption?: string | null
          country_code?: string
          created_at?: string
          expires_at?: string
          id?: string
          kind: string
          media_path: string
          status?: string
          thumbnail_path?: string | null
          view_count?: number
        }
        Update: {
          author_id?: string
          caption?: string | null
          country_code?: string
          created_at?: string
          expires_at?: string
          id?: string
          kind?: string
          media_path?: string
          status?: string
          thumbnail_path?: string | null
          view_count?: number
        }
        Relationships: [
          {
            foreignKeyName: "stories_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "stories_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
        ]
      }
      story_highlight_items: {
        Row: {
          created_at: string
          highlight_id: string
          sort_order: number
          story_id: string
        }
        Insert: {
          created_at?: string
          highlight_id: string
          sort_order?: number
          story_id: string
        }
        Update: {
          created_at?: string
          highlight_id?: string
          sort_order?: number
          story_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "story_highlight_items_highlight_id_fkey"
            columns: ["highlight_id"]
            isOneToOne: false
            referencedRelation: "story_highlights"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "story_highlight_items_story_id_fkey"
            columns: ["story_id"]
            isOneToOne: false
            referencedRelation: "stories"
            referencedColumns: ["id"]
          },
        ]
      }
      story_highlights: {
        Row: {
          cover_path: string | null
          created_at: string
          id: string
          owner_id: string
          sort_order: number
          story_count: number
          title: string
          updated_at: string
        }
        Insert: {
          cover_path?: string | null
          created_at?: string
          id?: string
          owner_id: string
          sort_order?: number
          story_count?: number
          title: string
          updated_at?: string
        }
        Update: {
          cover_path?: string | null
          created_at?: string
          id?: string
          owner_id?: string
          sort_order?: number
          story_count?: number
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "story_highlights_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      story_views: {
        Row: {
          story_id: string
          viewed_at: string
          viewer_id: string
        }
        Insert: {
          story_id: string
          viewed_at?: string
          viewer_id: string
        }
        Update: {
          story_id?: string
          viewed_at?: string
          viewer_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "story_views_story_id_fkey"
            columns: ["story_id"]
            isOneToOne: false
            referencedRelation: "stories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "story_views_viewer_id_fkey"
            columns: ["viewer_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      stripe_events: {
        Row: {
          id: string
          order_id: string | null
          payload: Json
          processed_at: string | null
          received_at: string
          result: Json | null
          type: string
        }
        Insert: {
          id: string
          order_id?: string | null
          payload: Json
          processed_at?: string | null
          received_at?: string
          result?: Json | null
          type: string
        }
        Update: {
          id?: string
          order_id?: string | null
          payload?: Json
          processed_at?: string | null
          received_at?: string
          result?: Json | null
          type?: string
        }
        Relationships: [
          {
            foreignKeyName: "stripe_events_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      user_interests: {
        Row: {
          created_at: string
          id: string
          interest: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          interest: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          interest?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_interests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      user_profiles: {
        Row: {
          age_confirmed_at: string | null
          avatar_url: string | null
          bio: string | null
          country_code: string
          cover_url: string | null
          created_at: string
          currency_code: string
          display_name: string
          follower_count: number
          following_count: number
          friend_count: number
          home_municipality_id: string | null
          home_region_id: string | null
          hunting_unit_id: string | null
          id: string
          last_seen_at: string | null
          locale: string
          outing_count: number
          post_count: number
          search_tsv: unknown
          seller_rating_avg: number | null
          seller_rating_count: number
          status: string
          unit_system: string
          updated_at: string
          username: string
          verification_expires_at: string | null
          verification_level: string
          verified_at: string | null
        }
        Insert: {
          age_confirmed_at?: string | null
          avatar_url?: string | null
          bio?: string | null
          country_code?: string
          cover_url?: string | null
          created_at?: string
          currency_code?: string
          display_name: string
          follower_count?: number
          following_count?: number
          friend_count?: number
          home_municipality_id?: string | null
          home_region_id?: string | null
          hunting_unit_id?: string | null
          id: string
          last_seen_at?: string | null
          locale?: string
          outing_count?: number
          post_count?: number
          search_tsv?: unknown
          seller_rating_avg?: number | null
          seller_rating_count?: number
          status?: string
          unit_system?: string
          updated_at?: string
          username: string
          verification_expires_at?: string | null
          verification_level?: string
          verified_at?: string | null
        }
        Update: {
          age_confirmed_at?: string | null
          avatar_url?: string | null
          bio?: string | null
          country_code?: string
          cover_url?: string | null
          created_at?: string
          currency_code?: string
          display_name?: string
          follower_count?: number
          following_count?: number
          friend_count?: number
          home_municipality_id?: string | null
          home_region_id?: string | null
          hunting_unit_id?: string | null
          id?: string
          last_seen_at?: string | null
          locale?: string
          outing_count?: number
          post_count?: number
          search_tsv?: unknown
          seller_rating_avg?: number | null
          seller_rating_count?: number
          status?: string
          unit_system?: string
          updated_at?: string
          username?: string
          verification_expires_at?: string | null
          verification_level?: string
          verified_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "user_profiles_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "user_profiles_currency_code_fkey"
            columns: ["currency_code"]
            isOneToOne: false
            referencedRelation: "currencies"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "user_profiles_home_municipality_id_fkey"
            columns: ["home_municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_profiles_home_region_id_fkey"
            columns: ["home_region_id"]
            isOneToOne: false
            referencedRelation: "regions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_profiles_hunting_unit_id_fkey"
            columns: ["hunting_unit_id"]
            isOneToOne: false
            referencedRelation: "hunting_units"
            referencedColumns: ["id"]
          },
        ]
      }
      user_settings: {
        Row: {
          birth_date: string | null
          created_at: string
          digest_weekly: boolean
          email_enabled: boolean
          message_policy: string
          notification_prefs: Json
          onboarding_completed_at: string | null
          push_enabled: boolean
          show_location: boolean
          show_sensitive: boolean
          theme: string
          updated_at: string
          user_id: string
        }
        Insert: {
          birth_date?: string | null
          created_at?: string
          digest_weekly?: boolean
          email_enabled?: boolean
          message_policy?: string
          notification_prefs?: Json
          onboarding_completed_at?: string | null
          push_enabled?: boolean
          show_location?: boolean
          show_sensitive?: boolean
          theme?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          birth_date?: string | null
          created_at?: string
          digest_weekly?: boolean
          email_enabled?: boolean
          message_policy?: string
          notification_prefs?: Json
          onboarding_completed_at?: string | null
          push_enabled?: boolean
          show_location?: boolean
          show_sensitive?: boolean
          theme?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_settings_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      user_strikes: {
        Row: {
          country_code: string
          created_at: string
          details: string | null
          expires_at: string
          id: string
          issued_by: string | null
          reason: string
          report_id: string | null
          revoke_note: string | null
          revoked_at: string | null
          revoked_by: string | null
          user_id: string
        }
        Insert: {
          country_code?: string
          created_at?: string
          details?: string | null
          expires_at?: string
          id?: string
          issued_by?: string | null
          reason: string
          report_id?: string | null
          revoke_note?: string | null
          revoked_at?: string | null
          revoked_by?: string | null
          user_id: string
        }
        Update: {
          country_code?: string
          created_at?: string
          details?: string | null
          expires_at?: string
          id?: string
          issued_by?: string | null
          reason?: string
          report_id?: string | null
          revoke_note?: string | null
          revoked_at?: string | null
          revoked_by?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_strikes_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "user_strikes_issued_by_fkey"
            columns: ["issued_by"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_strikes_report_id_fkey"
            columns: ["report_id"]
            isOneToOne: false
            referencedRelation: "reports"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_strikes_revoked_by_fkey"
            columns: ["revoked_by"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_strikes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      verification_requests: {
        Row: {
          badge_type: string
          country_code: string
          created_at: string
          declared_data: Json
          document_path: string | null
          documents: Json
          documents_purged_at: string | null
          expires_at: string | null
          id: string
          page_id: string | null
          rejection_reason: string | null
          reminded_at: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          badge_type: string
          country_code?: string
          created_at?: string
          declared_data?: Json
          document_path?: string | null
          documents?: Json
          documents_purged_at?: string | null
          expires_at?: string | null
          id?: string
          page_id?: string | null
          rejection_reason?: string | null
          reminded_at?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          badge_type?: string
          country_code?: string
          created_at?: string
          declared_data?: Json
          document_path?: string | null
          documents?: Json
          documents_purged_at?: string | null
          expires_at?: string | null
          id?: string
          page_id?: string | null
          rejection_reason?: string | null
          reminded_at?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "verification_requests_page_id_fkey"
            columns: ["page_id"]
            isOneToOne: false
            referencedRelation: "pages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "verification_requests_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "verification_requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      weather_cache: {
        Row: {
          cache_key: string
          created_at: string
          expires_at: string
          fetched_at: string
          hit_count: number
          lat: number
          lng: number
          municipality_id: string | null
          payload: Json
          source: string
          timezone: string | null
        }
        Insert: {
          cache_key: string
          created_at?: string
          expires_at?: string
          fetched_at?: string
          hit_count?: number
          lat: number
          lng: number
          municipality_id?: string | null
          payload: Json
          source?: string
          timezone?: string | null
        }
        Update: {
          cache_key?: string
          created_at?: string
          expires_at?: string
          fetched_at?: string
          hit_count?: number
          lat?: number
          lng?: number
          municipality_id?: string | null
          payload?: Json
          source?: string
          timezone?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "weather_cache_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      active_strike_count: { Args: { p_user: string }; Returns: number }
      add_album_media: {
        Args: { p_album_id: string; p_items: Json }
        Returns: string[]
      }
      add_conversation_participants: {
        Args: { p_conversation_id: string; p_user_ids: string[] }
        Returns: undefined
      }
      add_outing_media: {
        Args: { p_items: Json; p_log_id: string }
        Returns: string[]
      }
      add_page_member: {
        Args: { p_page_id: string; p_role?: string; p_username: string }
        Returns: {
          member_id: string
          role: string
          user_id: string
        }[]
      }
      are_friends: { Args: { a: string; b: string }; Returns: boolean }
      attach_checkout_session: {
        Args: {
          p_expires_at?: string
          p_order_id: string
          p_payment_intent_id?: string
          p_session_id: string
        }
        Returns: undefined
      }
      auto_complete_orders: { Args: never; Returns: number }
      auto_report: {
        Args: {
          p_author: string
          p_country: string
          p_details: string
          p_target_id: string
          p_target_type: string
        }
        Returns: undefined
      }
      ban_forum_member: {
        Args: { p_member_id: string; p_reason?: string }
        Returns: undefined
      }
      ban_group_member: {
        Args: { p_member_id: string; p_reason?: string }
        Returns: undefined
      }
      banned_words_severity: {
        Args: { p_country: string; p_text: string }
        Returns: string
      }
      block_user: { Args: { p_user: string }; Returns: undefined }
      browse_listings: {
        Args: {
          p_category_id?: string
          p_conditions?: string[]
          p_country?: string
          p_currency?: string
          p_lat?: number
          p_limit?: number
          p_lng?: number
          p_municipality_id?: string
          p_offset?: number
          p_price_max_minor?: number
          p_price_min_minor?: number
          p_q?: string
          p_radius_km?: number
          p_region_id?: string
          p_seller_id?: string
          p_shipping?: boolean
          p_sort?: string
        }
        Returns: {
          category_id: string
          category_slug: string
          condition: string
          created_at: string
          currency_code: string
          display_currency: string
          display_price_minor: number
          distance_m: number
          expires_at: string
          favorite_count: number
          id: string
          is_favorite: boolean
          is_mediated: boolean
          lat: number
          lng: number
          media_count: number
          media_path: string
          municipality: string
          negotiable: boolean
          price_minor: number
          rate_date: string
          region_name: string
          seller_avatar_url: string
          seller_display_name: string
          seller_id: string
          seller_rating_avg: number
          seller_rating_count: number
          seller_username: string
          seller_verification_level: string
          shipping_available: boolean
          shop_name: string
          status: string
          title: string
          view_count: number
        }[]
      }
      calendar_overview: {
        Args: {
          p_applies_to?: string
          p_date?: string
          p_lat?: number
          p_lng?: number
          p_region_id: string
        }
        Returns: {
          bag_day: number
          bag_season: number
          calendar_id: string
          category: string
          closes_at: string
          is_open: boolean
          is_open_now: boolean
          name_it: string
          next_open: string
          notes: string
          opens_at: string
          scientific_name: string
          season_label: string
          source_name: string
          source_url: string
          species_id: string
          time_rule: string
          valid_from: string
          valid_to: string
        }[]
      }
      can_message: {
        Args: { p_from: string; p_target: string }
        Returns: boolean
      }
      can_view_album: {
        Args: { p_album_id: string; p_viewer: string }
        Returns: boolean
      }
      can_view_dog: {
        Args: { p_dog_id: string; p_viewer: string }
        Returns: boolean
      }
      can_view_forum: { Args: { fid: string; uid: string }; Returns: boolean }
      can_view_group: { Args: { gid: string; uid: string }; Returns: boolean }
      can_view_group_content: {
        Args: { gid: string; uid: string }
        Returns: boolean
      }
      can_view_listing: { Args: { lid: string; uid: string }; Returns: boolean }
      can_view_log: { Args: { lid: string; uid: string }; Returns: boolean }
      can_view_order: {
        Args: { p_order_id: string; p_viewer: string }
        Returns: boolean
      }
      can_view_post: { Args: { pid: string; uid: string }; Returns: boolean }
      can_view_sighting: {
        Args: { p_id: string; p_viewer: string }
        Returns: boolean
      }
      cancel_friend_request: {
        Args: { p_request_id: string }
        Returns: undefined
      }
      cancel_order: {
        Args: { p_order_id: string; p_reason?: string }
        Returns: Json
      }
      cancel_verification_request: { Args: { p_id: string }; Returns: string[] }
      checkin_participant: {
        Args: { p_participant_id: string }
        Returns: {
          checked_in_at: string
          status: string
        }[]
      }
      checkin_ticket: {
        Args: { p_code: string }
        Returns: {
          avatar_url: string
          checked_in_at: string
          display_name: string
          event_id: string
          event_title: string
          participant_id: string
          status: string
          user_id: string
          username: string
        }[]
      }
      comment_post_id: { Args: { cid: string }; Returns: string }
      confirm_order_received: {
        Args: { p_order_id: string }
        Returns: undefined
      }
      contact_seller: {
        Args: { p_listing_id: string; p_message?: string }
        Returns: string
      }
      country_policies_overview: {
        Args: never
        Returns: {
          allow_harvest_photos: boolean
          allowed_types: Json
          blur_harvest_photos: boolean
          country_code: string
          country_name: string
          firearms_listings: number
          firearms_mode: string
          gun_shops_verified: number
          is_active: boolean
          minimum_age: number
          notice_key: string
          requires_badge: string
          updated_at: string
        }[]
      }
      create_album: {
        Args: { p_description?: string; p_title: string; p_visibility?: string }
        Returns: string
      }
      create_comment: {
        Args: { p_content: string; p_parent_id?: string; p_post_id: string }
        Returns: string
      }
      create_event: {
        Args: {
          p_address?: string
          p_capacity?: number
          p_category: string
          p_cover_url?: string
          p_currency_code?: string
          p_description?: string
          p_ends_at?: string
          p_hunting_unit_id?: string
          p_lat?: number
          p_lng?: number
          p_location_name?: string
          p_organizer_group_id?: string
          p_organizer_page_id?: string
          p_price_minor?: number
          p_publish?: boolean
          p_region_id?: string
          p_starts_at: string
          p_title: string
        }
        Returns: string
      }
      create_forum: {
        Args: {
          p_avatar_url?: string
          p_category?: string
          p_cover_url?: string
          p_description?: string
          p_name: string
          p_visibility?: string
        }
        Returns: {
          id: string
          slug: string
        }[]
      }
      create_group: {
        Args: {
          p_avatar_url?: string
          p_category?: string
          p_cover_url?: string
          p_description?: string
          p_join_policy?: string
          p_name: string
          p_region_id?: string
          p_visibility?: string
        }
        Returns: {
          id: string
          slug: string
        }[]
      }
      create_group_conversation: {
        Args: { p_title: string; p_user_ids: string[] }
        Returns: string
      }
      create_order: {
        Args: {
          p_buyer_note?: string
          p_delivery_method?: string
          p_event_id?: string
          p_listing_id?: string
          p_shipping_address?: Json
        }
        Returns: string
      }
      create_page: {
        Args: {
          p_address?: string
          p_avatar_url?: string
          p_category: string
          p_cover_url?: string
          p_description?: string
          p_email?: string
          p_name: string
          p_phone?: string
          p_region_id?: string
          p_website?: string
        }
        Returns: {
          id: string
          slug: string
        }[]
      }
      create_post: {
        Args: {
          p_content?: string
          p_group_id?: string
          p_hunting_unit_id?: string
          p_is_sensitive?: boolean
          p_kind: string
          p_lat?: number
          p_lng?: number
          p_location_name?: string
          p_media?: Json
          p_page_id?: string
          p_poll?: Json
          p_visibility?: string
        }
        Returns: string
      }
      create_reply: {
        Args: {
          p_attachments?: Json
          p_content: string
          p_parent_id?: string
          p_thread_id: string
        }
        Returns: string
      }
      create_thread: {
        Args: {
          p_attachments?: Json
          p_content?: string
          p_forum_id: string
          p_tags?: string[]
          p_title: string
        }
        Returns: string
      }
      decide_order_refund: {
        Args: { p_approve: boolean; p_note?: string; p_order_id: string }
        Returns: Json
      }
      delete_album: { Args: { p_album_id: string }; Returns: string[] }
      delete_dog: { Args: { p_id: string }; Returns: string[] }
      delete_dog_health: { Args: { p_id: string }; Returns: undefined }
      delete_dog_trial: { Args: { p_id: string }; Returns: string[] }
      delete_map_point: { Args: { p_id: string }; Returns: undefined }
      delete_map_zone: { Args: { p_id: string }; Returns: undefined }
      delete_message: { Args: { p_message_id: string }; Returns: undefined }
      delete_outing: { Args: { p_id: string }; Returns: string[] }
      delete_seller_review: { Args: { p_id: string }; Returns: undefined }
      delete_sighting: { Args: { p_id: string }; Returns: string[] }
      delete_sighting_alert: { Args: { p_id: string }; Returns: undefined }
      diary_season_stats: {
        Args: { p_season?: string; p_user?: string }
        Returns: Json
      }
      diary_seasons: {
        Args: { p_user?: string }
        Returns: {
          first_outing: string
          harvests: number
          last_outing: string
          outings: number
          season_label: string
        }[]
      }
      direct_conversation_between: {
        Args: { a: string; b: string }
        Returns: string
      }
      dog_profile: { Args: { p_dog_id: string }; Returns: Json }
      dogs_of: {
        Args: { p_user?: string }
        Returns: {
          avatar_url: string
          birth_date: string
          breed: string
          breed_id: string
          breed_names: Json
          harvest_total: number
          id: string
          name: string
          outing_count: number
          owner_id: string
          post_count: number
          sex: string
          status: string
          trial_count: number
          visibility: string
        }[]
      }
      edit_message: {
        Args: { p_body: string; p_message_id: string }
        Returns: undefined
      }
      ensure_billing_customer: {
        Args: { p_stripe_customer_id: string; p_user_id: string }
        Returns: undefined
      }
      event_going_preview: {
        Args: { p_event_id: string }
        Returns: {
          avatar_url: string
          display_name: string
          is_friend: boolean
          user_id: string
          username: string
          verification_level: string
        }[]
      }
      event_organizer_summary: {
        Args: { p_event_id: string }
        Returns: {
          capacity: number
          checked_in: number
          going: number
          interested: number
          is_paid_event: boolean
          paid: number
          pending_payment: number
          waitlist: number
        }[]
      }
      events_nearby: {
        Args: {
          p_lat: number
          p_limit?: number
          p_lng: number
          p_radius_km?: number
        }
        Returns: {
          address: string | null
          attendee_count: number
          capacity: number | null
          category: string
          country_code: string
          cover_url: string | null
          created_at: string
          created_by: string
          currency_code: string
          description: string | null
          ends_at: string | null
          hunting_unit_id: string | null
          id: string
          interested_count: number
          lat: number | null
          lng: number | null
          location_name: string | null
          organizer_group_id: string | null
          organizer_page_id: string | null
          organizer_user_id: string | null
          price_minor: number
          region_id: string | null
          search_tsv: unknown
          starts_at: string
          status: string
          title: string
          updated_at: string
        }[]
        SetofOptions: {
          from: "*"
          to: "events"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      expire_listings: { Args: never; Returns: number }
      expire_pending_orders: { Args: never; Returns: number }
      expire_stories: { Args: never; Returns: number }
      extract_hashtags: { Args: { p_text: string }; Returns: string[] }
      extract_mentions: { Args: { p_text: string }; Returns: string[] }
      f_unaccent: { Args: { p: string }; Returns: string }
      feed_following: {
        Args: {
          p_before_created_at?: string
          p_before_id?: string
          p_limit?: number
        }
        Returns: {
          author_id: string
          comment_count: number
          content: string | null
          country_code: string
          created_at: string
          group_id: string | null
          hunting_unit_id: string | null
          id: string
          is_sensitive: boolean
          kind: string
          lat: number | null
          lng: number | null
          location_name: string | null
          page_id: string | null
          reaction_count: number
          search_tsv: unknown
          share_count: number
          shared_post_id: string | null
          status: string
          updated_at: string
          visibility: string
        }[]
        SetofOptions: {
          from: "*"
          to: "posts"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      feed_for_you: {
        Args: {
          p_before_created_at?: string
          p_before_id?: string
          p_country?: string
          p_limit?: number
        }
        Returns: {
          author_id: string
          comment_count: number
          content: string | null
          country_code: string
          created_at: string
          group_id: string | null
          hunting_unit_id: string | null
          id: string
          is_sensitive: boolean
          kind: string
          lat: number | null
          lng: number | null
          location_name: string | null
          page_id: string | null
          reaction_count: number
          search_tsv: unknown
          share_count: number
          shared_post_id: string | null
          status: string
          updated_at: string
          visibility: string
        }[]
        SetofOptions: {
          from: "*"
          to: "posts"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      feed_group: {
        Args: {
          p_before_created_at?: string
          p_before_id?: string
          p_group_id: string
          p_limit?: number
        }
        Returns: {
          author_id: string
          comment_count: number
          content: string | null
          country_code: string
          created_at: string
          group_id: string | null
          hunting_unit_id: string | null
          id: string
          is_sensitive: boolean
          kind: string
          lat: number | null
          lng: number | null
          location_name: string | null
          page_id: string | null
          reaction_count: number
          search_tsv: unknown
          share_count: number
          shared_post_id: string | null
          status: string
          updated_at: string
          visibility: string
        }[]
        SetofOptions: {
          from: "*"
          to: "posts"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      feed_nearby: {
        Args: {
          p_before_created_at?: string
          p_before_id?: string
          p_limit?: number
        }
        Returns: {
          author_id: string
          comment_count: number
          content: string | null
          country_code: string
          created_at: string
          group_id: string | null
          hunting_unit_id: string | null
          id: string
          is_sensitive: boolean
          kind: string
          lat: number | null
          lng: number | null
          location_name: string | null
          page_id: string | null
          reaction_count: number
          search_tsv: unknown
          share_count: number
          shared_post_id: string | null
          status: string
          updated_at: string
          visibility: string
        }[]
        SetofOptions: {
          from: "*"
          to: "posts"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      feed_page: {
        Args: {
          p_before_created_at?: string
          p_before_id?: string
          p_limit?: number
          p_page_id: string
        }
        Returns: {
          author_id: string
          comment_count: number
          content: string | null
          country_code: string
          created_at: string
          group_id: string | null
          hunting_unit_id: string | null
          id: string
          is_sensitive: boolean
          kind: string
          lat: number | null
          lng: number | null
          location_name: string | null
          page_id: string | null
          reaction_count: number
          search_tsv: unknown
          share_count: number
          shared_post_id: string | null
          status: string
          updated_at: string
          visibility: string
        }[]
        SetofOptions: {
          from: "*"
          to: "posts"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      forum_rank: { Args: { p_role: string }; Returns: number }
      forum_reply_depth: { Args: { p_reply_id: string }; Returns: number }
      forum_reports: {
        Args: { p_forum_id: string; p_open?: boolean }
        Returns: {
          author_display_name: string
          author_id: string
          author_username: string
          created_at: string
          details: string
          id: string
          preview: string
          priority: string
          reason: string
          reporter_username: string
          status: string
          target_id: string
          target_type: string
          thread_id: string
          thread_title: string
        }[]
      }
      forum_role: { Args: { fid: string; uid: string }; Returns: string }
      forum_studio_stats: {
        Args: { p_days?: number; p_forum_id: string }
        Returns: Json
      }
      forum_studio_summary: {
        Args: { p_forum_id: string }
        Returns: {
          banned_count: number
          member_count: number
          my_role: string
          pending_count: number
          thread_count: number
        }[]
      }
      forum_top_tags: {
        Args: { p_forum_id: string; p_limit?: number }
        Returns: {
          tag: string
          thread_count: number
        }[]
      }
      forum_visibility: { Args: { fid: string }; Returns: string }
      group_join_policy: { Args: { gid: string }; Returns: string }
      group_rank: { Args: { p_role: string }; Returns: number }
      group_role: { Args: { gid: string; uid: string }; Returns: string }
      group_studio_stats: {
        Args: { p_days?: number; p_group_id: string }
        Returns: Json
      }
      group_studio_summary: {
        Args: { p_group_id: string }
        Returns: {
          banned_count: number
          member_count: number
          my_role: string
          pending_count: number
          post_count: number
        }[]
      }
      group_visibility: { Args: { gid: string }; Returns: string }
      has_admin_role: {
        Args: { roles: string[]; uid: string }
        Returns: boolean
      }
      hb_ads_charge_event: {
        Args: { p_object: Json; p_type: string }
        Returns: Json
      }
      hb_calendar_open_on: {
        Args: { p_applies_to?: string; p_calendar_id: string; p_date: string }
        Returns: boolean
      }
      hb_convert_minor: {
        Args: { p_amount: number; p_from: string; p_to: string }
        Returns: number
      }
      hb_display_currency: { Args: { p_currency?: string }; Returns: string }
      hb_distance_m: {
        Args: { lat1: number; lat2: number; lng1: number; lng2: number }
        Returns: number
      }
      hb_do_checkin: {
        Args: {
          e: Database["public"]["Tables"]["events"]["Row"]
          p: Database["public"]["Tables"]["event_participants"]["Row"]
          p_uid: string
        }
        Returns: undefined
      }
      hb_firearms_policy: { Args: { p_country?: string }; Returns: Json }
      hb_geojson_bbox: {
        Args: { p_geojson: Json }
        Returns: {
          max_lat: number
          max_lng: number
          min_lat: number
          min_lng: number
        }[]
      }
      hb_insert_attachments: {
        Args: {
          p_country: string
          p_items: Json
          p_reply_id: string
          p_thread_id: string
        }
        Returns: undefined
      }
      hb_job_allowed: { Args: never; Returns: boolean }
      hb_latest_rate: {
        Args: { p_from: string; p_to: string }
        Returns: {
          rate: number
          valid_on: string
        }[]
      }
      hb_moon_phase: {
        Args: { p_at?: string }
        Returns: {
          age_days: number
          illumination: number
          phase: number
          phase_name: string
        }[]
      }
      hb_normalize_tag: { Args: { p: string }; Returns: string }
      hb_notify_forum_mentions: {
        Args: {
          p_actor: string
          p_data: Json
          p_forum_id: string
          p_target_id: string
          p_target_type: string
          p_text: string
        }
        Returns: undefined
      }
      hb_order_event: {
        Args: {
          p_actor: string
          p_data?: Json
          p_kind: string
          p_order_id: string
        }
        Returns: undefined
      }
      hb_payment_method_in_use: { Args: { p_id: string }; Returns: boolean }
      hb_platform_fee_minor: {
        Args: { p_amount_minor: number; p_kind: string }
        Returns: number
      }
      hb_point_in_geojson: {
        Args: { p_geojson: Json; p_lat: number; p_lng: number }
        Returns: boolean
      }
      hb_point_in_ring: {
        Args: { p_lat: number; p_lng: number; p_ring: Json }
        Returns: boolean
      }
      hb_polygon_area_m2: { Args: { p_geojson: Json }; Returns: number }
      hb_promote_waitlist: { Args: { p_event_id: string }; Returns: undefined }
      hb_regexp_escape: { Args: { p: string }; Returns: string }
      hb_search_query: { Args: { p_text: string }; Returns: unknown }
      hb_season_bounds: {
        Args: { p_country?: string; p_label: string }
        Returns: {
          season_from: string
          season_to: string
        }[]
      }
      hb_season_label: {
        Args: { p_country?: string; p_date: string }
        Returns: string
      }
      hb_service_allowed: { Args: never; Returns: boolean }
      hb_slugify: { Args: { p: string }; Returns: string }
      hb_species_name: {
        Args: { p_locale?: string; p_species_id: string }
        Returns: string
      }
      hb_sun_offset: {
        Args: { p_part: string; p_rise: string; p_set: string }
        Returns: string
      }
      hb_sun_times: {
        Args: { p_date: string; p_lat: number; p_lng: number }
        Returns: {
          sunrise: string
          sunset: string
        }[]
      }
      hb_sync_thread_tags: {
        Args: { p_tags: string[]; p_text: string; p_thread_id: string }
        Returns: undefined
      }
      hb_system_message: {
        Args: { p_conversation_id: string; p_event: string; p_meta: Json }
        Returns: undefined
      }
      hb_ticket_code: { Args: never; Returns: string }
      hb_time_window: {
        Args: {
          p_date: string
          p_lat: number
          p_lng: number
          p_time_rule: string
          p_timezone?: string
        }
        Returns: {
          closes_at: string
          opens_at: string
        }[]
      }
      hb_tsv: { Args: { p_a: string; p_b?: string }; Returns: unknown }
      hb_user_limit: {
        Args: { p_key: string; p_user: string }
        Returns: number
      }
      hb_validate_attachments: {
        Args: { p_items: Json; p_uid: string }
        Returns: undefined
      }
      hb_validate_polygon: { Args: { p_geojson: Json }; Returns: boolean }
      hb_viewer_country: { Args: { p_country?: string }; Returns: string }
      hide_post: { Args: { p_post_id: string }; Returns: undefined }
      highlight_owner_id: { Args: { hid: string }; Returns: string }
      hunting_day: {
        Args: {
          p_applies_to?: string
          p_date?: string
          p_lat?: number
          p_lng?: number
          p_region_id: string
          p_species_id: string
          p_unit_id?: string
        }
        Returns: Json
      }
      is_active_account: { Args: { uid: string }; Returns: boolean }
      is_admin: { Args: { uid: string }; Returns: boolean }
      is_blocked: { Args: { a: string; b: string }; Returns: boolean }
      is_conversation_owner: {
        Args: { cid: string; uid: string }
        Returns: boolean
      }
      is_conversation_participant: {
        Args: { cid: string; uid: string }
        Returns: boolean
      }
      is_event_organizer: {
        Args: { eid: string; uid: string }
        Returns: boolean
      }
      is_following: {
        Args: { followed: string; follower: string }
        Returns: boolean
      }
      is_forum_manager: { Args: { fid: string; uid: string }; Returns: boolean }
      is_forum_member: { Args: { fid: string; uid: string }; Returns: boolean }
      is_forum_owner: { Args: { fid: string; uid: string }; Returns: boolean }
      is_group_manager: { Args: { gid: string; uid: string }; Returns: boolean }
      is_group_member: { Args: { gid: string; uid: string }; Returns: boolean }
      is_group_owner: { Args: { gid: string; uid: string }; Returns: boolean }
      is_listing_seller: {
        Args: { lid: string; uid: string }
        Returns: boolean
      }
      is_log_owner: { Args: { lid: string; uid: string }; Returns: boolean }
      is_moderator: { Args: { uid: string }; Returns: boolean }
      is_page_manager: { Args: { pid: string; uid: string }; Returns: boolean }
      is_page_owner: { Args: { pid: string; uid: string }; Returns: boolean }
      is_post_author: { Args: { pid: string; uid: string }; Returns: boolean }
      is_story_author: { Args: { sid: string; uid: string }; Returns: boolean }
      is_story_highlighted: { Args: { sid: string }; Returns: boolean }
      issue_strike: {
        Args: {
          p_days?: number
          p_details?: string
          p_reason: string
          p_report_id?: string
          p_user: string
        }
        Returns: {
          active_strikes: number
          strike_id: string
          user_status: string
        }[]
      }
      join_forum: {
        Args: { p_forum_id: string }
        Returns: {
          role: string
          status: string
        }[]
      }
      join_group: {
        Args: { p_group_id: string }
        Returns: {
          role: string
          status: string
        }[]
      }
      leave_conversation: {
        Args: { p_conversation_id: string }
        Returns: undefined
      }
      leave_forum: { Args: { p_forum_id: string }; Returns: undefined }
      leave_group: { Args: { p_group_id: string }; Returns: undefined }
      list_blocked: {
        Args: never
        Returns: {
          avatar_url: string
          blocked_at: string
          display_name: string
          id: string
          username: string
          verification_level: string
        }[]
      }
      list_conversations: {
        Args: { p_limit?: number; p_offset?: number }
        Returns: {
          created_at: string
          created_by: string
          id: string
          is_blocked: boolean
          kind: string
          last_message: Json
          last_message_at: string
          muted_until: string
          my_last_read_at: string
          my_role: string
          participants: Json
          title: string
          unread_count: number
        }[]
      }
      list_dog_breeds: {
        Args: never
        Returns: {
          created_at: string
          fci_group: number | null
          id: string
          names: Json
          origin: string | null
          slug: string
          sort_order: number
          work_type: string
        }[]
        SetofOptions: {
          from: "*"
          to: "dog_breeds"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      list_forum_threads: {
        Args: {
          p_author?: string
          p_filter?: string
          p_forum_id: string
          p_limit?: number
          p_offset?: number
          p_since?: string
          p_sort?: string
          p_tag?: string
        }
        Returns: {
          author_id: string
          content: string | null
          country_code: string
          created_at: string
          forum_id: string
          id: string
          is_locked: boolean
          is_pinned: boolean
          last_reply_at: string | null
          reply_count: number
          search_tsv: unknown
          solution_reply_id: string | null
          status: string
          title: string
          updated_at: string
          view_count: number
        }[]
        SetofOptions: {
          from: "*"
          to: "forum_threads"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      list_friends: {
        Args: { p_limit?: number; p_offset?: number; p_user_id: string }
        Returns: {
          avatar_url: string
          display_name: string
          friends_since: string
          id: string
          mutual: boolean
          username: string
          verification_level: string
        }[]
      }
      list_muted: {
        Args: never
        Returns: {
          avatar_url: string
          display_name: string
          id: string
          muted_at: string
          username: string
          verification_level: string
        }[]
      }
      list_outings: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_season?: string
          p_user?: string
        }
        Returns: {
          cover_path: string
          cover_thumbnail_path: string
          dogs: Json
          duration_min: number
          ended_at: string
          harvest_total: number
          hunting_method: string
          id: string
          media_count: number
          municipality_name: string
          region_name: string
          season_label: string
          species: Json
          started_at: string
          title: string
          unit_name: string
          user_id: string
          visibility: string
          weather: Json
          zone_name: string
        }[]
      }
      list_recent_threads: {
        Args: {
          p_country?: string
          p_limit?: number
          p_offset?: number
          p_sort?: string
          p_tag?: string
        }
        Returns: {
          author_id: string
          content: string | null
          country_code: string
          created_at: string
          forum_id: string
          id: string
          is_locked: boolean
          is_pinned: boolean
          last_reply_at: string | null
          reply_count: number
          search_tsv: unknown
          solution_reply_id: string | null
          status: string
          title: string
          updated_at: string
          view_count: number
        }[]
        SetofOptions: {
          from: "*"
          to: "forum_threads"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      listing_detail: {
        Args: { p_country?: string; p_currency?: string; p_id: string }
        Returns: Json
      }
      map_overview: {
        Args: {
          p_lat: number
          p_limit?: number
          p_lng: number
          p_radius_km?: number
        }
        Returns: Json
      }
      mark_all_notifications_read: { Args: never; Returns: number }
      mark_conversation_read: {
        Args: { p_conversation_id: string }
        Returns: undefined
      }
      mark_event_paid: {
        Args: { p_paid?: boolean; p_participant_id: string }
        Returns: {
          payment_status: string
          ticket_code: string
        }[]
      }
      mark_notification_read: { Args: { p_id: string }; Returns: undefined }
      mark_order_shipped: {
        Args: {
          p_carrier?: string
          p_order_id: string
          p_tracking_code?: string
        }
        Returns: undefined
      }
      mark_payment_method_failed: {
        Args: { p_code?: string; p_stripe_pm_id: string }
        Returns: undefined
      }
      mark_story_viewed: { Args: { p_story_id: string }; Returns: number }
      mark_thread_solution: {
        Args: { p_reply_id?: string; p_thread_id: string }
        Returns: undefined
      }
      mark_verification_documents_purged: {
        Args: { p_ids: string[] }
        Returns: number
      }
      marketplace_categories: {
        Args: { p_country?: string }
        Returns: {
          available: boolean
          id: string
          is_restricted: boolean
          mode: string
          name_key: string
          notice_key: string
          parent_id: string
          requires_badge: string
          slug: string
          sort_order: number
        }[]
      }
      minimum_age_for: { Args: { p_country: string }; Returns: number }
      mute_user: { Args: { p_user: string }; Returns: undefined }
      my_dog_reminders: {
        Args: { p_days?: number }
        Returns: {
          days_left: number
          dog_id: string
          dog_name: string
          due_on: string
          kind: string
          record_id: string
          title: string
        }[]
      }
      my_favorite_listings: {
        Args: { p_limit?: number; p_offset?: number }
        Returns: {
          currency_code: string
          display_currency: string
          display_price_minor: number
          favorited_at: string
          listing_id: string
          media_path: string
          municipality: string
          price_minor: number
          seller_display_name: string
          status: string
          title: string
        }[]
      }
      my_listings: {
        Args: { p_limit?: number; p_offset?: number; p_status?: string }
        Returns: {
          category_id: string
          category_slug: string
          condition: string
          contact_count: number
          created_at: string
          currency_code: string
          days_left: number
          expires_at: string
          favorite_count: number
          id: string
          is_mediated: boolean
          media_count: number
          media_path: string
          municipality: string
          price_minor: number
          reserved_at: string
          sold_at: string
          status: string
          title: string
          updated_at: string
          view_count: number
        }[]
      }
      my_orders: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_role?: string
          p_status?: string
        }
        Returns: {
          amount_minor: number
          can_cancel: boolean
          can_confirm: boolean
          can_request_refund: boolean
          can_ship: boolean
          completed_at: string
          counterpart_avatar_url: string
          counterpart_display_name: string
          counterpart_id: string
          counterpart_username: string
          created_at: string
          currency_code: string
          delivery_method: string
          event_id: string
          expires_at: string
          id: string
          kind: string
          listing_id: string
          media_path: string
          paid_at: string
          platform_fee_minor: number
          seller_payout_minor: number
          shipped_at: string
          shipping_minor: number
          status: string
          title: string
          total_minor: number
          tracking_carrier: string
          tracking_code: string
          updated_at: string
        }[]
      }
      my_pages: {
        Args: never
        Returns: {
          address: string | null
          avatar_url: string | null
          category: string
          country_code: string
          cover_url: string | null
          created_at: string
          description: string | null
          email: string | null
          follower_count: number
          id: string
          name: string
          owner_id: string
          phone: string | null
          post_count: number
          region_id: string | null
          search_tsv: unknown
          slug: string
          status: string
          updated_at: string
          verification_status: string
          verified_at: string | null
          website: string | null
        }[]
        SetofOptions: {
          from: "*"
          to: "pages"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      my_payment_methods: {
        Args: never
        Returns: {
          brand: string
          country_code: string
          created_at: string
          exp_month: number
          exp_year: number
          id: string
          is_default: boolean
          last_failure_code: string
          last4: string
          status: string
          type: string
        }[]
      }
      my_seller_payouts_summary: { Args: never; Returns: Json }
      my_sighting_alerts: {
        Args: never
        Returns: {
          cooldown_min: number
          created_at: string
          fire_count: number
          id: string
          is_active: boolean
          kinds: string[]
          last_fired_at: string
          lat: number
          lng: number
          min_animals: number
          municipality_id: string
          municipality_name: string
          name: string
          radius_km: number
          region_id: string
          region_name: string
          species_id: string
          species_name: string
        }[]
      }
      my_sightings: {
        Args: {
          p_limit?: number
          p_log_id?: string
          p_offset?: number
          p_season?: string
          p_species_id?: string
        }
        Returns: {
          accuracy_m: number
          animals_count: number
          category: string
          id: string
          kind: string
          lat: number
          lng: number
          log_id: string
          media_path: string
          municipality_name: string
          notes: string
          region_name: string
          scientific_name: string
          season_label: string
          sighted_at: string
          species_id: string
          species_name: string
          thumbnail_path: string
          unit_name: string
          visibility: string
        }[]
      }
      my_strikes: {
        Args: never
        Returns: {
          created_at: string
          details: string
          expires_at: string
          id: string
          reason: string
        }[]
      }
      my_verification: { Args: never; Returns: Json }
      next_changes: {
        Args: { p_days?: number; p_from?: string; p_region_id: string }
        Returns: {
          calendar_id: string
          category: string
          change_date: string
          kind: string
          name_it: string
          notes: string
          scientific_name: string
          species_id: string
        }[]
      }
      notify_user: {
        Args: {
          p_actor: string
          p_data?: Json
          p_kind: string
          p_target_id: string
          p_target_type: string
          p_user: string
        }
        Returns: undefined
      }
      order_detail: { Args: { p_order_id: string }; Returns: Json }
      order_for_payment: { Args: { p_order_id: string }; Returns: Json }
      order_quote: {
        Args: { p_delivery_method?: string; p_listing_id: string }
        Returns: Json
      }
      page_studio_stats: {
        Args: { p_days?: number; p_page_id: string }
        Returns: Json
      }
      page_studio_summary: {
        Args: { p_page_id: string }
        Returns: {
          follower_count: number
          my_role: string
          post_count: number
          status: string
          team_count: number
          verification_status: string
        }[]
      }
      poll_post_id: { Args: { pid: string }; Returns: string }
      process_stripe_event: {
        Args: { p_event_id: string; p_payload: Json; p_type: string }
        Returns: Json
      }
      reactions_names: {
        Args: { p_post_ids: string[] }
        Returns: {
          display_name: string
          post_id: string
          user_id: string
          username: string
        }[]
      }
      reactions_summary: {
        Args: { p_post_ids: string[] }
        Returns: {
          is_mine: boolean
          post_id: string
          reaction_count: number
          reaction_type: string
        }[]
      }
      record_listing_view: { Args: { p_id: string }; Returns: undefined }
      regions_with_calendars: {
        Args: { p_country?: string }
        Returns: {
          calendars: number
          code: string
          country_code: string
          kind: string
          name: string
          region_id: string
          season_label: string
        }[]
      }
      register_push_token: {
        Args: { p_platform: string; p_token: string }
        Returns: undefined
      }
      relationship_with: {
        Args: { p_user: string }
        Returns: {
          blocked_by_me: boolean
          blocked_me: boolean
          incoming_request_id: string
          is_followed_by: boolean
          is_following: boolean
          is_friend: boolean
          muted_by_me: boolean
          outgoing_request_id: string
        }[]
      }
      remove_album_media: { Args: { p_media_id: string }; Returns: string[] }
      remove_conversation_participant: {
        Args: { p_conversation_id: string; p_user: string }
        Returns: undefined
      }
      remove_forum_member: { Args: { p_member_id: string }; Returns: undefined }
      remove_friend: { Args: { p_user: string }; Returns: undefined }
      remove_group_member: { Args: { p_member_id: string }; Returns: undefined }
      remove_outing_media: { Args: { p_media_id: string }; Returns: string[] }
      remove_page_member: { Args: { p_member_id: string }; Returns: undefined }
      remove_payment_method: { Args: { p_id: string }; Returns: string }
      rename_conversation: {
        Args: { p_conversation_id: string; p_title: string }
        Returns: undefined
      }
      renew_listing: { Args: { p_id: string }; Returns: string }
      reorder_album_media: {
        Args: { p_album_id: string; p_media_ids: string[] }
        Returns: undefined
      }
      reply_seller_review: {
        Args: { p_id: string; p_reply: string }
        Returns: undefined
      }
      reply_thread_id: { Args: { rid: string }; Returns: string }
      report_content: {
        Args: {
          p_details?: string
          p_reason: string
          p_target_id: string
          p_target_type: string
        }
        Returns: string
      }
      request_order_refund: {
        Args: { p_order_id: string; p_reason: string }
        Returns: undefined
      }
      resolve_forum_report: {
        Args: { p_action: string; p_note?: string; p_report_id: string }
        Returns: undefined
      }
      respond_friend_request: {
        Args: { p_accept: boolean; p_request_id: string }
        Returns: {
          is_friend: boolean
          status: string
        }[]
      }
      review_forum_request: {
        Args: { p_accept: boolean; p_member_id: string }
        Returns: {
          status: string
        }[]
      }
      review_join_request: {
        Args: { p_accept: boolean; p_member_id: string }
        Returns: {
          status: string
        }[]
      }
      review_verification_request: {
        Args: {
          p_decision: string
          p_expires_at?: string
          p_id: string
          p_reason?: string
        }
        Returns: undefined
      }
      revoke_strike: {
        Args: { p_note?: string; p_strike_id: string }
        Returns: {
          active_strikes: number
          user_status: string
        }[]
      }
      rsvp_event: {
        Args: { p_event_id: string; p_status: string }
        Returns: {
          payment_status: string
          status: string
          ticket_code: string
          waitlist_position: number
        }[]
      }
      run_verification_maintenance: { Args: never; Returns: Json }
      search_all: {
        Args: { p_limit?: number; p_q: string }
        Returns: {
          extra: Json
          id: string
          image_url: string
          kind: string
          rank: number
          slug: string
          subtitle: string
          title: string
          total: number
        }[]
      }
      search_dogs: {
        Args: {
          p_breed_id?: string
          p_limit?: number
          p_offset?: number
          p_query?: string
          p_region_id?: string
        }
        Returns: {
          avatar_url: string
          birth_date: string
          breed: string
          breed_id: string
          id: string
          kennel_name: string
          name: string
          outing_count: number
          owner_avatar_url: string
          owner_display_name: string
          owner_id: string
          owner_username: string
          region_name: string
          sex: string
          trial_count: number
        }[]
      }
      search_events: {
        Args: { p_limit?: number; p_offset?: number; p_q: string }
        Returns: {
          address: string | null
          attendee_count: number
          capacity: number | null
          category: string
          country_code: string
          cover_url: string | null
          created_at: string
          created_by: string
          currency_code: string
          description: string | null
          ends_at: string | null
          hunting_unit_id: string | null
          id: string
          interested_count: number
          lat: number | null
          lng: number | null
          location_name: string | null
          organizer_group_id: string | null
          organizer_page_id: string | null
          organizer_user_id: string | null
          price_minor: number
          region_id: string | null
          search_tsv: unknown
          starts_at: string
          status: string
          title: string
          updated_at: string
        }[]
        SetofOptions: {
          from: "*"
          to: "events"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      search_forum_threads: {
        Args: { p_limit?: number; p_offset?: number; p_q: string }
        Returns: {
          author_id: string
          content: string | null
          country_code: string
          created_at: string
          forum_id: string
          id: string
          is_locked: boolean
          is_pinned: boolean
          last_reply_at: string | null
          reply_count: number
          search_tsv: unknown
          solution_reply_id: string | null
          status: string
          title: string
          updated_at: string
          view_count: number
        }[]
        SetofOptions: {
          from: "*"
          to: "forum_threads"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      search_groups: {
        Args: { p_limit?: number; p_offset?: number; p_q: string }
        Returns: {
          avatar_url: string | null
          category: string | null
          country_code: string
          cover_url: string | null
          created_at: string
          description: string | null
          id: string
          join_policy: string
          member_count: number
          name: string
          owner_id: string
          post_count: number
          region_id: string | null
          search_tsv: unknown
          slug: string
          status: string
          updated_at: string
          visibility: string
        }[]
        SetofOptions: {
          from: "*"
          to: "groups"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      search_hashtags: {
        Args: { p_limit?: number; p_q: string }
        Returns: {
          created_at: string
          id: string
          post_count: number
          search_tsv: unknown
          tag: string
          thread_count: number
        }[]
        SetofOptions: {
          from: "*"
          to: "hashtags"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      search_listings: {
        Args: { p_limit?: number; p_offset?: number; p_q: string }
        Returns: {
          attributes: Json
          category_id: string
          condition: string
          contact_count: number
          country_code: string
          created_at: string
          currency_code: string
          description: string | null
          expires_at: string | null
          favorite_count: number
          id: string
          is_mediated: boolean
          lat: number | null
          lng: number | null
          media_count: number
          municipality: string | null
          municipality_id: string | null
          negotiable: boolean
          page_id: string | null
          price_minor: number
          region_id: string | null
          reserved_at: string | null
          search_tsv: unknown
          seller_id: string
          shipping_available: boolean
          sold_at: string | null
          status: string
          title: string
          updated_at: string
          view_count: number
        }[]
        SetofOptions: {
          from: "*"
          to: "listings"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      search_municipalities: {
        Args: {
          p_country?: string
          p_limit?: number
          p_query: string
          p_region_id?: string
        }
        Returns: {
          id: string
          istat_code: string
          name: string
          name_alt: string
          province_code: string
          province_name: string
          region_id: string
          region_name: string
        }[]
      }
      search_pages: {
        Args: { p_limit?: number; p_offset?: number; p_q: string }
        Returns: {
          address: string | null
          avatar_url: string | null
          category: string
          country_code: string
          cover_url: string | null
          created_at: string
          description: string | null
          email: string | null
          follower_count: number
          id: string
          name: string
          owner_id: string
          phone: string | null
          post_count: number
          region_id: string | null
          search_tsv: unknown
          slug: string
          status: string
          updated_at: string
          verification_status: string
          verified_at: string | null
          website: string | null
        }[]
        SetofOptions: {
          from: "*"
          to: "pages"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      search_posts: {
        Args: { p_limit?: number; p_offset?: number; p_q: string }
        Returns: {
          author_id: string
          comment_count: number
          content: string | null
          country_code: string
          created_at: string
          group_id: string | null
          hunting_unit_id: string | null
          id: string
          is_sensitive: boolean
          kind: string
          lat: number | null
          lng: number | null
          location_name: string | null
          page_id: string | null
          reaction_count: number
          search_tsv: unknown
          share_count: number
          shared_post_id: string | null
          status: string
          updated_at: string
          visibility: string
        }[]
        SetofOptions: {
          from: "*"
          to: "posts"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      search_profiles: {
        Args: { p_limit?: number; p_offset?: number; p_q: string }
        Returns: {
          age_confirmed_at: string | null
          avatar_url: string | null
          bio: string | null
          country_code: string
          cover_url: string | null
          created_at: string
          currency_code: string
          display_name: string
          follower_count: number
          following_count: number
          friend_count: number
          home_municipality_id: string | null
          home_region_id: string | null
          hunting_unit_id: string | null
          id: string
          last_seen_at: string | null
          locale: string
          outing_count: number
          post_count: number
          search_tsv: unknown
          seller_rating_avg: number | null
          seller_rating_count: number
          status: string
          unit_system: string
          updated_at: string
          username: string
          verification_expires_at: string | null
          verification_level: string
          verified_at: string | null
        }[]
        SetofOptions: {
          from: "*"
          to: "user_profiles"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      seller_account_status: { Args: never; Returns: Json }
      seller_profile: { Args: { p_user: string }; Returns: Json }
      seller_reviews_of: {
        Args: { p_limit?: number; p_offset?: number; p_user: string }
        Returns: {
          comment: string
          created_at: string
          id: string
          is_mine: boolean
          listing_id: string
          listing_title: string
          rating: number
          reply: string
          reply_at: string
          reviewer_avatar_url: string
          reviewer_display_name: string
          reviewer_id: string
          reviewer_username: string
        }[]
      }
      send_friend_request: {
        Args: { p_message?: string; p_user: string }
        Returns: {
          request_id: string
          status: string
        }[]
      }
      send_message: {
        Args: {
          p_body?: string
          p_client_id?: string
          p_conversation_id: string
          p_duration_ms?: number
          p_kind?: string
          p_media_height?: number
          p_media_mime?: string
          p_media_path?: string
          p_media_size?: number
          p_media_width?: number
          p_reply_to_id?: string
        }
        Returns: string
      }
      set_album_cover: {
        Args: { p_album_id: string; p_cover_path?: string; p_media_id: string }
        Returns: string
      }
      set_conversation_muted: {
        Args: { p_conversation_id: string; p_until: string }
        Returns: undefined
      }
      set_default_payment_method: { Args: { p_id: string }; Returns: undefined }
      set_dog_status: {
        Args: { p_deceased_on?: string; p_id: string; p_status: string }
        Returns: undefined
      }
      set_event_status: {
        Args: { p_event_id: string; p_status: string }
        Returns: undefined
      }
      set_forum_member_role: {
        Args: { p_member_id: string; p_role: string }
        Returns: {
          role: string
        }[]
      }
      set_forum_status: {
        Args: { p_forum_id: string; p_status: string }
        Returns: undefined
      }
      set_group_member_role: {
        Args: { p_member_id: string; p_role: string }
        Returns: {
          role: string
        }[]
      }
      set_group_status: {
        Args: { p_group_id: string; p_status: string }
        Returns: undefined
      }
      set_listing_media: {
        Args: { p_items: Json; p_listing_id: string }
        Returns: string[]
      }
      set_listing_status: {
        Args: { p_id: string; p_status: string }
        Returns: undefined
      }
      set_page_member_role: {
        Args: { p_member_id: string; p_role: string }
        Returns: {
          role: string
        }[]
      }
      set_page_status: {
        Args: { p_page_id: string; p_status: string }
        Returns: undefined
      }
      set_platform_setting: {
        Args: { p_key: string; p_value: Json }
        Returns: undefined
      }
      set_sighting_alert_active: {
        Args: { p_active: boolean; p_id: string }
        Returns: undefined
      }
      set_thread_locked: {
        Args: { p_locked: boolean; p_thread_id: string }
        Returns: undefined
      }
      set_thread_pinned: {
        Args: { p_pinned: boolean; p_thread_id: string }
        Returns: undefined
      }
      set_thread_status: {
        Args: { p_status: string; p_thread_id: string }
        Returns: undefined
      }
      set_unit_area: {
        Args: { p_geojson: Json; p_source?: string; p_unit_id: string }
        Returns: undefined
      }
      shared_post: {
        Args: { "": Database["public"]["Tables"]["posts"]["Row"] }
        Returns: {
          author_id: string
          comment_count: number
          content: string | null
          country_code: string
          created_at: string
          group_id: string | null
          hunting_unit_id: string | null
          id: string
          is_sensitive: boolean
          kind: string
          lat: number | null
          lng: number | null
          location_name: string | null
          page_id: string | null
          reaction_count: number
          search_tsv: unknown
          share_count: number
          shared_post_id: string | null
          status: string
          updated_at: string
          visibility: string
        }
        SetofOptions: {
          from: "posts"
          to: "posts"
          isOneToOne: true
          isSetofReturn: true
        }
      }
      show_limit: { Args: never; Returns: number }
      show_trgm: { Args: { "": string }; Returns: string[] }
      sighting_detail: { Args: { p_id: string }; Returns: Json }
      sightings_heatmap: {
        Args: {
          p_from?: string
          p_lat: number
          p_lng: number
          p_radius_km?: number
          p_species_id?: string
          p_to?: string
        }
        Returns: {
          animals: number
          cell_lat: number
          cell_lng: number
          last_at: string
          sightings: number
          species_count: number
          top_species_id: string
          top_species_name: string
        }[]
      }
      sightings_nearby: {
        Args: {
          p_from?: string
          p_lat: number
          p_limit?: number
          p_lng: number
          p_radius_km?: number
          p_species_id?: string
          p_to?: string
        }
        Returns: {
          animals_count: number
          author_avatar_url: string
          author_display_name: string
          author_id: string
          author_username: string
          category: string
          distance_m: number
          id: string
          is_exact: boolean
          is_mine: boolean
          kind: string
          lat: number
          lng: number
          media_path: string
          municipality_name: string
          scientific_name: string
          sighted_at: string
          species_id: string
          species_name: string
          thumbnail_path: string
          visibility: string
        }[]
      }
      sightings_of: {
        Args: { p_limit?: number; p_offset?: number; p_user: string }
        Returns: {
          animals_count: number
          category: string
          id: string
          is_exact: boolean
          kind: string
          lat: number
          lng: number
          media_path: string
          municipality_name: string
          region_name: string
          scientific_name: string
          sighted_at: string
          species_id: string
          species_name: string
          thumbnail_path: string
          visibility: string
        }[]
      }
      species_activity: {
        Args: {
          p_days?: number
          p_lat?: number
          p_lng?: number
          p_radius_km?: number
          p_region_id?: string
          p_species_id?: string
        }
        Returns: {
          animals: number
          category: string
          last_at: string
          prev_sightings: number
          scientific_name: string
          sightings: number
          species_id: string
          species_name: string
          trend_pct: number
        }[]
      }
      start_direct_conversation: { Args: { p_user: string }; Returns: string }
      stories_tray: {
        Args: never
        Returns: {
          author_id: string
          avatar_url: string
          display_name: string
          latest_at: string
          latest_kind: string
          latest_media_path: string
          latest_thumbnail_path: string
          story_count: number
          unseen_count: number
          username: string
          verification_level: string
        }[]
      }
      submit_verification_request: {
        Args: {
          p_badge_type: string
          p_declared_data?: Json
          p_documents?: Json
          p_page_id?: string
        }
        Returns: string
      }
      subscribe_thread: {
        Args: { p_on?: boolean; p_thread_id: string }
        Returns: {
          subscribed: boolean
        }[]
      }
      suggest_groups: {
        Args: { p_limit?: number }
        Returns: {
          avatar_url: string
          category: string
          id: string
          matches_interest: boolean
          member_count: number
          name: string
          region_id: string
          same_region: boolean
          slug: string
        }[]
      }
      suggest_profiles: {
        Args: { p_limit?: number }
        Returns: {
          avatar_url: string
          display_name: string
          follower_count: number
          id: string
          mutual_friends: number
          same_region: boolean
          shared_interests: number
          username: string
          verification_level: string
        }[]
      }
      tag_post_dogs: {
        Args: { p_dog_ids: string[]; p_post_id: string }
        Returns: undefined
      }
      thread_forum_id: { Args: { tid: string }; Returns: string }
      thread_is_open: { Args: { tid: string }; Returns: boolean }
      toggle_comment_like: {
        Args: { p_comment_id: string }
        Returns: {
          like_count: number
          liked: boolean
        }[]
      }
      toggle_listing_favorite: { Args: { p_id: string }; Returns: boolean }
      toggle_reaction: {
        Args: { p_post_id: string; p_reaction_type: string }
        Returns: {
          my_reaction: string
          reaction_count: number
        }[]
      }
      toggle_reply_like: {
        Args: { p_reply_id: string }
        Returns: {
          like_count: number
          liked: boolean
        }[]
      }
      touch_presence: { Args: never; Returns: undefined }
      touch_thread_view: { Args: { p_thread_id: string }; Returns: undefined }
      unaccent: { Args: { "": string }; Returns: string }
      unban_forum_member: { Args: { p_member_id: string }; Returns: undefined }
      unban_group_member: { Args: { p_member_id: string }; Returns: undefined }
      unblock_user: { Args: { p_user: string }; Returns: undefined }
      undo_checkin: { Args: { p_participant_id: string }; Returns: undefined }
      unhide_post: { Args: { p_post_id: string }; Returns: undefined }
      unit_at_point: {
        Args: { p_lat: number; p_lng: number }
        Returns: {
          code: string
          name: string
          region_id: string
          region_name: string
          unit_id: string
          unit_type: string
        }[]
      }
      unmute_user: { Args: { p_user: string }; Returns: undefined }
      unread_conversations_count: { Args: never; Returns: number }
      unread_notifications_count: { Args: never; Returns: number }
      unregister_push_token: { Args: { p_token: string }; Returns: undefined }
      update_album: {
        Args: {
          p_album_id: string
          p_description?: string
          p_title: string
          p_visibility?: string
        }
        Returns: undefined
      }
      update_album_media: {
        Args: { p_caption?: string; p_media_id: string; p_taken_at?: string }
        Returns: undefined
      }
      update_outing_media: {
        Args: { p_caption?: string; p_media_id: string }
        Returns: undefined
      }
      update_thread_tags: {
        Args: { p_tags: string[]; p_thread_id: string }
        Returns: undefined
      }
      upsert_country_policy: {
        Args: { p_country: string; p_policy_data: Json; p_policy_type: string }
        Returns: undefined
      }
      upsert_dog: {
        Args: {
          p_avatar_url?: string
          p_birth_date?: string
          p_breed_id?: string
          p_breeder_page_id?: string
          p_color?: string
          p_cover_url?: string
          p_description?: string
          p_father_name?: string
          p_id?: string
          p_kennel_name?: string
          p_microchip_number?: string
          p_mother_name?: string
          p_name?: string
          p_pedigree_number?: string
          p_sex?: string
          p_visibility?: string
          p_weight_kg?: number
        }
        Returns: string
      }
      upsert_dog_health: {
        Args: {
          p_dog_id: string
          p_due_on?: string
          p_id?: string
          p_kind?: string
          p_notes?: string
          p_performed_on?: string
          p_title?: string
          p_vet_name?: string
        }
        Returns: string
      }
      upsert_dog_trial: {
        Args: {
          p_certificate_path?: string
          p_dog_id: string
          p_event_id?: string
          p_id?: string
          p_judge?: string
          p_kind?: string
          p_notes?: string
          p_organizer?: string
          p_place?: string
          p_points?: string
          p_result?: string
          p_title?: string
          p_trial_date?: string
        }
        Returns: string
      }
      upsert_listing: {
        Args: {
          p_attributes?: Json
          p_category_id?: string
          p_condition?: string
          p_currency_code?: string
          p_description?: string
          p_id?: string
          p_lat?: number
          p_lng?: number
          p_municipality_id?: string
          p_negotiable?: boolean
          p_price_minor?: number
          p_region_id?: string
          p_shipping_available?: boolean
          p_status?: string
          p_title?: string
        }
        Returns: string
      }
      upsert_map_point: {
        Args: {
          p_color?: string
          p_id?: string
          p_kind?: string
          p_lat?: number
          p_lng?: number
          p_name?: string
          p_notes?: string
          p_visibility?: string
        }
        Returns: string
      }
      upsert_map_zone: {
        Args: {
          p_color?: string
          p_geojson?: Json
          p_id?: string
          p_name?: string
          p_notes?: string
          p_visibility?: string
        }
        Returns: string
      }
      upsert_outing: {
        Args: {
          p_accuracy_m?: number
          p_distance_m?: number
          p_dog_ids?: string[]
          p_ended_at?: string
          p_hunting_unit_id?: string
          p_id?: string
          p_lat?: number
          p_lng?: number
          p_method?: string
          p_municipality_id?: string
          p_notes?: string
          p_region_id?: string
          p_species?: Json
          p_started_at?: string
          p_title?: string
          p_visibility?: string
          p_weather?: Json
          p_zone_name?: string
        }
        Returns: string
      }
      upsert_payment_method: {
        Args: {
          p_brand?: string
          p_country?: string
          p_exp_month?: number
          p_exp_year?: number
          p_last4?: string
          p_set_default?: boolean
          p_stripe_pm_id: string
          p_type?: string
          p_user_id: string
        }
        Returns: string
      }
      upsert_seller_account: {
        Args: {
          p_charges_enabled?: boolean
          p_country_code?: string
          p_default_currency?: string
          p_details_submitted?: boolean
          p_payouts_enabled?: boolean
          p_requirements?: Json
          p_stripe_account_id: string
          p_user_id: string
        }
        Returns: undefined
      }
      upsert_seller_review: {
        Args: { p_comment?: string; p_listing_id: string; p_rating: number }
        Returns: string
      }
      upsert_sighting: {
        Args: {
          p_accuracy_m?: number
          p_animals_count?: number
          p_id?: string
          p_kind?: string
          p_lat?: number
          p_lng?: number
          p_log_id?: string
          p_media_path?: string
          p_municipality_id?: string
          p_notes?: string
          p_region_id?: string
          p_sighted_at?: string
          p_species_id?: string
          p_thumbnail_path?: string
          p_visibility?: string
        }
        Returns: string
      }
      upsert_sighting_alert: {
        Args: {
          p_cooldown_min?: number
          p_id?: string
          p_is_active?: boolean
          p_kinds?: string[]
          p_lat?: number
          p_lng?: number
          p_min_animals?: number
          p_municipality_id?: string
          p_name?: string
          p_radius_km?: number
          p_region_id?: string
          p_species_id?: string
        }
        Returns: string
      }
      verification_documents_due_for_purge: {
        Args: { p_limit?: number }
        Returns: {
          id: string
          paths: string[]
          user_id: string
        }[]
      }
      verification_orphan_documents: {
        Args: { p_limit?: number }
        Returns: {
          created_at: string
          name: string
        }[]
      }
      verification_stats: { Args: never; Returns: Json }
      vote_poll: {
        Args: { p_option_ids: string[]; p_poll_id: string }
        Returns: {
          my_vote: boolean
          option_id: string
          total_votes: number
          vote_count: number
        }[]
      }
      weather_cache_key: {
        Args: { p_lat?: number; p_lng?: number; p_municipality_id?: string }
        Returns: string
      }
      weather_cache_prune: { Args: never; Returns: number }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
