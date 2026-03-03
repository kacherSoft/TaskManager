import SwiftUI

struct ManageDevicesView: View {
    @Environment(EntitlementService.self) private var entitlementService
    @Environment(\.dismiss) private var dismiss

    @State private var devices: [DeviceInfo] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var revokingInstallId: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Manage Devices")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Button("Refresh") {
                    Task { await reload() }
                }
                .disabled(isLoading || revokingInstallId != nil)
            }

            if isLoading {
                ProgressView("Loading devices…")
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if devices.isEmpty && !isLoading {
                Text("No devices found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                List(devices, id: \.install_id) { device in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(device.nickname ?? "Unnamed Device")
                                .font(.body)
                            HStack(spacing: 6) {
                                Text(shortInstallID(device.install_id))
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                if device.install_id == entitlementService.installId {
                                    Text("This Mac")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                            }
                            Text(statusText(for: device))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if device.active {
                            Button("Revoke") {
                                Task { await revoke(device) }
                            }
                            .buttonStyle(.bordered)
                            .disabled(revokingInstallId != nil)
                        } else {
                            Text("Revoked")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset)
                .frame(minHeight: 260)
            }

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 560, height: 430)
        .task {
            await reload()
        }
    }

    private func statusText(for device: DeviceInfo) -> String {
        if let revokedAt = device.revoked_at {
            return "Revoked at \(formattedUnix(revokedAt))"
        }
        return "Last seen \(formattedUnix(device.last_seen_at))"
    }

    private func formattedUnix(_ value: Int) -> String {
        Date(timeIntervalSince1970: TimeInterval(value))
            .formatted(date: .abbreviated, time: .shortened)
    }

    private func shortInstallID(_ installId: String) -> String {
        if installId.count <= 12 { return installId }
        let prefix = installId.prefix(8)
        let suffix = installId.suffix(4)
        return "\(prefix)…\(suffix)"
    }

    private func reload() async {
        guard entitlementService.isAccountSignedIn else {
            errorMessage = "Sign in is required"
            devices = []
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            devices = try await entitlementService.listAccountDevices()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func revoke(_ device: DeviceInfo) async {
        revokingInstallId = device.install_id
        errorMessage = nil
        defer { revokingInstallId = nil }

        do {
            try await entitlementService.revokeAccountDevice(installId: device.install_id)
            devices = try await entitlementService.listAccountDevices()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
