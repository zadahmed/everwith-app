from fastapi import APIRouter, Query
from fastapi.responses import HTMLResponse

router = APIRouter(tags=["legal"])

LAST_UPDATED = "November 19, 2025"


def _render_legal_page(active_section: str = "terms") -> str:
    active_section = active_section if active_section in {"terms", "privacy"} else "terms"

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>EverWith Legal</title>
    <style>
        :root {{
            color-scheme: light dark;
            --bg: #f7f7fb;
            --card: #ffffff;
            --text: #1e1b2d;
            --muted: #5d5871;
            --accent: #7c3aed;
            --border: #e3e1ec;
            font-family: "SF Pro Display", "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        }}
        * {{
            box-sizing: border-box;
        }}
        body {{
            margin: 0;
            background: var(--bg);
            color: var(--text);
            line-height: 1.65;
        }}
        .layout {{
            max-width: 960px;
            margin: 0 auto;
            padding: 2.5rem 1.5rem 4rem;
        }}
        header {{
            text-align: center;
            margin-bottom: 2rem;
        }}
        header h1 {{
            font-size: clamp(1.8rem, 3vw, 2.8rem);
            margin-bottom: 0.5rem;
        }}
        header p {{
            color: var(--muted);
            margin: 0.25rem 0;
        }}
        nav {{
            display: flex;
            gap: 1rem;
            justify-content: center;
            flex-wrap: wrap;
            margin-bottom: 2.5rem;
        }}
        nav a {{
            padding: 0.65rem 1.5rem;
            border-radius: 999px;
            border: 1px solid var(--border);
            text-decoration: none;
            color: var(--text);
            font-weight: 600;
            transition: all 0.2s ease;
        }}
        nav a.active {{
            background: var(--accent);
            color: #fff;
            border-color: var(--accent);
            box-shadow: 0 10px 25px rgba(124, 58, 237, 0.25);
        }}
        section {{
            background: var(--card);
            border-radius: 28px;
            padding: clamp(1.5rem, 3vw, 2.25rem);
            margin-bottom: 2rem;
            border: 1px solid var(--border);
            box-shadow: 0 30px 80px rgba(30, 27, 45, 0.08);
        }}
        h2 {{
            margin-top: 0;
            font-size: 1.4rem;
        }}
        h3 {{
            margin-bottom: 0.25rem;
            font-size: 1.05rem;
        }}
        ul {{
            padding-left: 1.2rem;
        }}
        .muted {{
            color: var(--muted);
        }}
        .pill {{
            display: inline-flex;
            align-items: center;
            gap: 0.35rem;
            padding: 0.35rem 0.85rem;
            border-radius: 999px;
            background: rgba(124, 58, 237, 0.08);
            color: var(--accent);
            font-weight: 600;
            font-size: 0.85rem;
        }}
        footer {{
            text-align: center;
            color: var(--muted);
            font-size: 0.9rem;
            margin-top: 2rem;
        }}
        @media (prefers-color-scheme: dark) {{
            :root {{
                --bg: #0f0b1c;
                --card: #181428;
                --text: #f8f5ff;
                --muted: #b3adc8;
                --border: rgba(255,255,255,0.08);
            }}
            section {{
                box-shadow: none;
            }}
        }}
    </style>
</head>
<body>
    <main class="layout">
        <header>
            <div class="pill">Updated {LAST_UPDATED}</div>
            <h1>EverWith Legal Center</h1>
            <p>These terms govern your access to EverWith’s AI-powered features.</p>
            <p class="muted">By continuing to use the app you agree to both policies below.</p>
        </header>

        <nav>
            <a class="{'active' if active_section == 'terms' else ''}" href="#terms">Terms & Conditions</a>
            <a class="{'active' if active_section == 'privacy' else ''}" href="#privacy">Privacy Policy</a>
        </nav>

        <section id="terms">
            <h2>Terms & Conditions</h2>
            <p class="muted">The EverWith app is provided on an "as-is" basis. We may update these terms at any time by posting a new version here. Material changes will be announced in-app. Continued use constitutes acceptance.</p>
            
            <h3>1. Your Eligibility & Account</h3>
            <ul>
                <li>You must be at least 13 years old (or the minimum age required in your region) to use EverWith. If you are under 18, you represent that you have your parent's or guardian's permission to use the service.</li>
                <li>For certain advanced AI features, you must be at least 18 years old. By using these features, you represent and warrant that you meet this age requirement.</li>
                <li>You must maintain accurate, current, and complete account information and safeguard your login credentials. You are responsible for all activities that occur under your account.</li>
                <li>You may not share your account credentials with others or use another person's account without authorization.</li>
                <li>We may suspend, restrict, or terminate accounts that violate these terms, applicable laws, or engage in fraudulent, abusive, or harmful conduct, with or without notice.</li>
                <li>You may not use the service if you are located in, or a resident of, any country subject to comprehensive trade sanctions or embargoes imposed by the United States, United Kingdom, European Union, or United Nations.</li>
            </ul>
            
            <h3>2. Acceptable Use & Prohibited Activities</h3>
            <p><strong>You may only upload or generate content you have the legal right to use, share, or modify.</strong> You are solely responsible for ensuring you have all necessary rights, permissions, and consents for any content you upload, process, or generate.</p>
            
            <p><strong>You agree NOT to use EverWith to:</strong></p>
            <ul>
                <li>Generate, upload, or share content that is illegal, harmful, threatening, abusive, harassing, defamatory, libelous, vulgar, obscene, pornographic, or otherwise objectionable.</li>
                <li>Create content that violates or infringes upon the rights of others, including intellectual property rights, privacy rights, publicity rights, or any other proprietary rights.</li>
                <li>Generate content that impersonates or misrepresents your affiliation with any person or entity, or that falsely suggests endorsement by any person or entity.</li>
                <li>Create deepfakes, manipulated media, or synthetic content intended to deceive, defraud, or harm others, including but not limited to non-consensual intimate imagery, political disinformation, or financial fraud.</li>
                <li>Use the service to identify, track, surveil, or infer private information about individuals without their explicit consent, including but not limited to facial recognition, biometric identification, or location tracking.</li>
                <li>Generate content that promotes violence, hate speech, discrimination, or harassment based on race, ethnicity, national origin, religion, gender, sexual orientation, age, disability, or other protected characteristics.</li>
                <li>Create content that exploits or harms minors, including but not limited to child sexual abuse material or content that could be harmful to minors.</li>
                <li>Use the service for any commercial purpose without explicit written authorization from EverWith, including but not limited to reselling access, creating competing services, or using outputs for commercial products.</li>
                <li>Reverse engineer, decompile, disassemble, or attempt to extract the source code of our AI models, algorithms, or proprietary technology.</li>
                <li>Interfere with, disrupt, or attempt to gain unauthorized access to our systems, networks, or other users' accounts.</li>
                <li>Use automated systems (bots, scrapers, etc.) to access the service, except through officially provided APIs.</li>
                <li>Violate any applicable local, state, national, or international law or regulation.</li>
            </ul>
            
            <p><strong>Content Responsibility:</strong> You are solely and entirely responsible for all prompts, references, photos, inputs, and outputs you generate, upload, or share through EverWith. EverWith does not monitor, review, or pre-screen every user request or generated output. We are not liable for any user-generated content, and you agree to indemnify and hold EverWith harmless from any claims arising from your use of the service.</p>
            
            <h3>3. AI Outputs, Accuracy & Disclaimers</h3>
            <p><strong>No Guarantees:</strong> Generative AI technology, including the models and algorithms used by EverWith, can produce inaccurate, unpredictable, unintended, biased, or erroneous results. AI-generated content may contain errors, inconsistencies, or artifacts. You acknowledge and agree that:</p>
            <ul>
                <li>AI outputs are generated by machine learning models and may not reflect reality, accuracy, or truth.</li>
                <li>Generated images, restorations, or merged content may contain inaccuracies, distortions, or unintended modifications.</li>
                <li>AI models may produce outputs that resemble real people, places, or copyrighted works based on training data, even when not explicitly requested.</li>
                <li>We do not guarantee that generated content will meet your expectations, be suitable for your intended use, comply with third-party platform policies, or avoid infringing upon any rights.</li>
                <li>You should independently review, verify, and validate all AI-generated outputs before using, sharing, publishing, or relying upon them for any purpose.</li>
                <li>AI outputs should not be used as the sole basis for important decisions, including but not limited to medical, legal, financial, or safety-critical applications.</li>
                <li>We make no representations or warranties regarding the accuracy, completeness, reliability, or quality of any AI-generated content.</li>
                <li>You assume all risks associated with using AI-generated content, including but not limited to legal, financial, reputational, or personal harm.</li>
            </ul>
            
            <p><strong>Beta Features:</strong> Some features may be labeled as "Beta" or "Experimental." These features are provided "as-is" without warranties of any kind. Beta features may be unstable, unavailable, or discontinued at any time without notice.</p>
            
            <h3>4. Intellectual Property Rights</h3>
            <ul>
                <li><strong>Your Content:</strong> You retain ownership of the original content you upload to EverWith. However, by uploading content, you grant EverWith a worldwide, non-exclusive, royalty-free, sublicensable, and transferable license to use, reproduce, distribute, prepare derivative works of, display, and perform your content solely for the purpose of providing, improving, and operating the EverWith service.</li>
                <li><strong>Generated Outputs:</strong> Subject to your compliance with these terms, you may use AI-generated outputs for your personal or commercial purposes. However, you acknowledge that:</li>
                <ul>
                    <li>Generated outputs may incorporate elements from our training data, which may include copyrighted material.</li>
                    <li>You are responsible for ensuring your use of generated outputs does not infringe upon third-party rights.</li>
                    <li>We make no representations or warranties regarding your ability to use generated outputs for any particular purpose.</li>
                </ul>
                <li><strong>EverWith Property:</strong> EverWith retains all right, title, and interest in and to the service, including but not limited to our AI models, algorithms, software, technology, trademarks, logos, and brand assets. These terms do not grant you any rights to use our trademarks, logos, or brand assets without our prior written consent.</li>
                <li><strong>Feedback:</strong> Any feedback, suggestions, or ideas you provide regarding EverWith may be used by us without obligation or compensation to you.</li>
            </ul>
            
            <h3>5. Subscriptions, Credits, Payments, and Refunds</h3>
            <ul>
                <li><strong>Subscriptions:</strong> Paid subscription plans automatically renew at the end of each billing period until you cancel through your device's App Store or Play Store settings, or through our in-app cancellation process.</li>
                <li><strong>Credits:</strong> Usage-based credits, if offered, are consumed when you initiate a generation request. Credits are non-refundable once consumed, even if the generation fails, produces unsatisfactory results, or is interrupted.</li>
                <li><strong>Pricing:</strong> We reserve the right to modify subscription prices, credit pricing, or feature availability at any time. Price changes will not affect your current billing period but will apply to subsequent renewals.</li>
                <li><strong>Payment Processing:</strong> Payments are processed by third-party payment processors (Apple, Google, etc.). You agree to their terms and conditions. EverWith does not store your full payment card information.</li>
                <li><strong>Taxes:</strong> You are responsible for all taxes, duties, carrier fees, or third-party platform fees associated with your use of the service.</li>
                <li><strong>Refunds:</strong> Refunds are handled in accordance with the policies of the App Store or Play Store from which you purchased. We may, at our sole discretion, provide refunds for exceptional circumstances, but we are not obligated to do so.</li>
                <li><strong>Chargebacks:</strong> If you initiate a chargeback or dispute a payment, we may suspend or terminate your account pending resolution.</li>
            </ul>
            
            <h3>6. Service Availability, Modifications, and Termination</h3>
            <ul>
                <li><strong>Availability:</strong> We strive to maintain service availability but do not guarantee uninterrupted, error-free, or secure access. The service may be unavailable due to maintenance, updates, technical issues, or circumstances beyond our control.</li>
                <li><strong>Modifications:</strong> We reserve the right to add, remove, modify, rate-limit, or discontinue features, functionality, or the entire service at any time, with or without notice, to maintain system health, comply with legal obligations, or for any other reason.</li>
                <li><strong>Rate Limiting:</strong> We may impose rate limits, usage quotas, or other restrictions on your use of the service to ensure fair usage and system stability.</li>
                <li><strong>Termination by You:</strong> You may stop using the service and delete your account at any time through the in-app settings or by contacting support.</li>
                <li><strong>Termination by Us:</strong> We may suspend, restrict, or terminate your access to the service immediately, without prior notice, if you violate these terms, engage in fraudulent or harmful conduct, or for any other reason we deem necessary to protect the service, other users, or our rights.</li>
                <li><strong>Effect of Termination:</strong> Upon termination, your right to use the service will immediately cease. We may delete your account data and content in accordance with our Privacy Policy, subject to applicable legal retention requirements.</li>
            </ul>
            
            <h3>7. Content Moderation & Enforcement</h3>
            <ul>
                <li>We reserve the right, but not the obligation, to monitor, review, filter, block, or remove any content or user activity that we determine, in our sole discretion, violates these terms, applicable laws, or is otherwise harmful or objectionable.</li>
                <li>We may use automated systems, human reviewers, or a combination thereof to detect and prevent prohibited content or activities.</li>
                <li>We are not obligated to monitor all content or activity, and you acknowledge that we may not detect all violations.</li>
                <li>If you believe content on our service violates these terms or your rights, please contact us at hello@codeai.studio with details.</li>
                <li>We may cooperate with law enforcement, regulatory authorities, or third parties in investigating and prosecuting violations of these terms or applicable laws.</li>
            </ul>
            
            <h3>8. Export Controls & Compliance</h3>
            <ul>
                <li>You agree to comply with all applicable export control laws and regulations, including but not limited to the Export Administration Regulations (EAR) and International Traffic in Arms Regulations (ITAR).</li>
                <li>You may not use the service to export, re-export, or transfer technology, software, or data in violation of any applicable export control laws.</li>
                <li>You represent that you are not located in, under the control of, or a national or resident of any country subject to comprehensive trade sanctions.</li>
            </ul>
            
            <h3>9. Warranties & Disclaimers</h3>
            <p><strong>THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO:</strong></p>
            <ul>
                <li>Implied warranties of merchantability, fitness for a particular purpose, non-infringement, or course of performance.</li>
                <li>Warranties that the service will be uninterrupted, error-free, secure, or free from viruses or other harmful components.</li>
                <li>Warranties regarding the accuracy, reliability, quality, or completeness of any content, information, or AI-generated outputs.</li>
                <li>Warranties that defects will be corrected or that the service will meet your requirements or expectations.</li>
            </ul>
            <p>Some jurisdictions do not allow the exclusion of certain warranties, so some of the above exclusions may not apply to you.</p>
            
            <h3>10. Limitation of Liability</h3>
            <p><strong>TO THE FULLEST EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL EVERWITH, ITS AFFILIATES, DIRECTORS, OFFICERS, EMPLOYEES, AGENTS, LICENSORS, OR SERVICE PROVIDERS BE LIABLE FOR:</strong></p>
            <ul>
                <li>Any indirect, incidental, special, consequential, exemplary, or punitive damages, including but not limited to loss of profits, revenue, data, goodwill, or other intangible losses.</li>
                <li>Damages resulting from your use or inability to use the service, unauthorized access to or alteration of your content, conduct or content of third parties, or any other matter relating to the service.</li>
                <li>Any damages arising from AI-generated content, including but not limited to defamation, privacy violations, intellectual property infringement, or personal or commercial harm.</li>
                <li>Any damages exceeding the total amount you paid to EverWith in the twelve (12) months preceding the claim, or $100, whichever is greater.</li>
            </ul>
            <p>Some jurisdictions do not allow the exclusion or limitation of incidental or consequential damages, so the above limitations may not apply to you. In such jurisdictions, our liability will be limited to the maximum extent permitted by law.</p>
            
            <h3>11. Indemnification</h3>
            <p>You agree to defend, indemnify, and hold harmless EverWith, its affiliates, licensors, and service providers, and their respective officers, directors, employees, agents, and representatives from and against any claims, liabilities, damages, judgments, awards, losses, costs, expenses, or fees (including reasonable attorneys' fees) arising out of or relating to:</p>
            <ul>
                <li>Your use of the service, including any content you upload, generate, or share.</li>
                <li>Your violation of these terms or any applicable law or regulation.</li>
                <li>Your violation of any third-party rights, including intellectual property, privacy, or publicity rights.</li>
                <li>Any content or activity that infringes upon or violates the rights of others.</li>
            </ul>
            <p>We reserve the right, at our own expense, to assume the exclusive defense and control of any matter subject to indemnification by you, in which case you agree to cooperate with our defense of such claims.</p>
            
            <h3>12. Dispute Resolution & Governing Law</h3>
            <ul>
                <li><strong>Informal Resolution:</strong> You agree to first contact us at hello@codeai.studio to attempt to resolve any dispute, claim, or controversy arising out of or relating to these terms or the service.</li>
                <li><strong>Governing Law:</strong> These terms are governed by and construed in accordance with the laws of the State of California, United States, without regard to its conflict of law provisions.</li>
                <li><strong>Jurisdiction:</strong> For any disputes that cannot be resolved informally, you agree to submit to the exclusive jurisdiction of the state and federal courts located in San Francisco County, California, United States.</li>
                <li><strong>Class Action Waiver:</strong> You agree that any disputes will be resolved individually, not as part of a class, collective, or representative action or proceeding.</li>
                <li><strong>Waiver of Jury Trial:</strong> You waive any right to a jury trial in connection with any dispute arising out of or relating to these terms or the service.</li>
            </ul>
            
            <h3>13. General Provisions</h3>
            <ul>
                <li><strong>Entire Agreement:</strong> These terms, together with our Privacy Policy, constitute the entire agreement between you and EverWith regarding the service.</li>
                <li><strong>Modifications:</strong> We may modify these terms at any time by posting updated terms. Material changes will be announced in-app or via email. Your continued use of the service after changes become effective constitutes acceptance of the modified terms.</li>
                <li><strong>Severability:</strong> If any provision of these terms is found to be unenforceable or invalid, that provision will be limited or eliminated to the minimum extent necessary, and the remaining provisions will remain in full force and effect.</li>
                <li><strong>Assignment:</strong> You may not assign or transfer these terms or your account without our prior written consent. We may assign or transfer these terms or our rights and obligations without restriction.</li>
                <li><strong>Waiver:</strong> Our failure to enforce any right or provision of these terms will not be deemed a waiver of such right or provision.</li>
                <li><strong>Contact:</strong> For questions about these terms, contact us at hello@codeai.studio.</li>
            </ul>
        </section>

        <section id="privacy">
            <h2>Privacy Policy</h2>
            <p class="muted">This notice explains how we collect, use, share, and safeguard personal data when you interact with EverWith. We are committed to protecting your privacy and being transparent about our data practices.</p>
            
            <h3>1. Information We Collect</h3>
            <p>We collect information that you provide directly, information we obtain automatically when you use our service, and information from third-party sources.</p>
            
            <p><strong>1.1 Information You Provide:</strong></p>
            <ul>
                <li><strong>Account Information:</strong> Name, email address, profile photo (if provided), authentication credentials, and account preferences.</li>
                <li><strong>Content Data:</strong> Photos, images, prompts, text inputs, metadata (EXIF data, timestamps, file names), and any other content you upload, submit, or generate through the service.</li>
                <li><strong>Communication Data:</strong> Messages, feedback, support requests, and other communications you send to us.</li>
                <li><strong>Payment Information:</strong> Payment method details are processed securely by third-party payment processors (Apple App Store, Google Play Store). We do not store your full payment card numbers, but we may receive transaction identifiers, subscription status, and billing information.</li>
            </ul>
            
            <p><strong>1.2 Information We Collect Automatically:</strong></p>
            <ul>
                <li><strong>Usage Data:</strong> Feature usage, interactions with the service, time spent, pages viewed, actions taken, and navigation patterns.</li>
                <li><strong>Device Information:</strong> Device type, operating system, device identifiers (such as IDFA, Android ID), hardware information, screen resolution, and device settings.</li>
                <li><strong>Log Data:</strong> IP address, browser type, access times, pages visited, referring URLs, crash reports, error logs, and performance data.</li>
                <li><strong>Location Data:</strong> General location information derived from IP address (country, region, city level), but not precise GPS coordinates unless you explicitly grant location permissions.</li>
                <li><strong>Cookies and Similar Technologies:</strong> We use cookies, web beacons, pixel tags, and similar technologies to collect information about your interactions with our service. You can control cookies through your browser settings.</li>
            </ul>
            
            <p><strong>1.3 Information from Third Parties:</strong></p>
            <ul>
                <li><strong>Authentication Providers:</strong> If you sign in using Google Sign-In or other third-party authentication services, we receive your name, email, and profile information as permitted by those services.</li>
                <li><strong>Payment Processors:</strong> Transaction information, subscription status, and billing details from Apple, Google, or other payment processors.</li>
                <li><strong>Analytics Providers:</strong> Aggregated usage statistics and analytics data from third-party analytics services.</li>
            </ul>
            
            <h3>2. How We Use Your Information</h3>
            <p>We use the information we collect for the following purposes:</p>
            <ul>
                <li><strong>Service Provision:</strong> To provide, operate, maintain, and improve the EverWith service, including processing your image generation requests, managing your account, and delivering AI-generated content.</li>
                <li><strong>Authentication & Security:</strong> To authenticate your identity, secure your account, prevent fraud, detect and prevent abuse, and protect the security and integrity of our service.</li>
                <li><strong>Personalization:</strong> To personalize your experience, customize content and features, and provide recommendations based on your usage patterns.</li>
                <li><strong>Communication:</strong> To send you service-related notifications, updates, security alerts, administrative messages, and respond to your inquiries and support requests.</li>
                <li><strong>Payment Processing:</strong> To process payments, manage subscriptions, track credit usage, handle refunds, and prevent fraudulent transactions.</li>
                <li><strong>Analytics & Improvement:</strong> To analyze usage patterns, understand how users interact with our service, identify trends, improve our AI models and algorithms, and develop new features.</li>
                <li><strong>Legal Compliance:</strong> To comply with applicable laws, regulations, legal processes, government requests, enforce our Terms of Service, protect our rights and the rights of others, and respond to legal claims.</li>
                <li><strong>Research & Development:</strong> To conduct research, develop new technologies, improve AI model performance, and advance the field of generative AI, subject to appropriate safeguards and anonymization where applicable.</li>
            </ul>
            
            <h3>3. How We Share Your Information</h3>
            <p>We do not sell your personal information. We share your information only in the following circumstances:</p>
            
            <p><strong>3.1 Service Providers & Vendors:</strong></p>
            <ul>
                <li><strong>Cloud Infrastructure:</strong> We share data with cloud hosting providers (e.g., AWS, Google Cloud, Heroku) to store and process your content and operate our service.</li>
                <li><strong>AI Model Providers:</strong> Your content may be processed by third-party AI model providers or APIs to generate outputs. These providers are contractually obligated to protect your data and use it solely for service provision.</li>
                <li><strong>Payment Processors:</strong> We share payment information with Apple, Google, and other payment processors to process transactions and manage subscriptions.</li>
                <li><strong>Analytics Services:</strong> We share aggregated, anonymized usage data with analytics providers to understand service performance and user behavior.</li>
                <li><strong>Customer Support:</strong> We may use third-party customer support platforms to manage and respond to your inquiries.</li>
            </ul>
            <p>All service providers are contractually required to maintain the confidentiality of your information and use it only for the purposes we specify.</p>
            
            <p><strong>3.2 Legal Requirements:</strong></p>
            <ul>
                <li>We may disclose your information if required by law, regulation, legal process, government request, or court order.</li>
                <li>We may share information to enforce our Terms of Service, protect our rights, property, or safety, or the rights, property, or safety of our users or others.</li>
                <li>We may disclose information in connection with legal proceedings, investigations, or claims.</li>
            </ul>
            
            <p><strong>3.3 Business Transfers:</strong></p>
            <ul>
                <li>In the event of a merger, acquisition, reorganization, bankruptcy, or sale of assets, your information may be transferred to the acquiring entity, subject to the same privacy protections.</li>
            </ul>
            
            <p><strong>3.4 With Your Consent:</strong></p>
            <ul>
                <li>We may share your information with third parties when you explicitly consent to such sharing.</li>
            </ul>
            
            <h3>4. Data Retention & Deletion</h3>
            <ul>
                <li><strong>Content Data:</strong> Uploaded photos and input images are typically deleted or anonymized within 30 days after processing, unless you explicitly request that we retain them for your account history. Generated outputs are retained only if you save them to your account.</li>
                <li><strong>Account Data:</strong> We retain your account information, authentication data, and preferences while your account is active and for a reasonable period after account deletion to comply with legal obligations, resolve disputes, and enforce agreements.</li>
                <li><strong>Billing Records:</strong> We retain billing and transaction records for the minimum period required by law (typically 7 years for tax and accounting purposes).</li>
                <li><strong>Usage & Analytics Data:</strong> Aggregated, anonymized usage data may be retained indefinitely for analytics and service improvement purposes.</li>
                <li><strong>Legal Holds:</strong> We may retain your information for longer periods if required by law, legal process, or to protect our legal rights.</li>
                <li><strong>Deletion Requests:</strong> You may request deletion of your account and associated data at any time through in-app settings or by contacting us. We will delete your data within 30 days, subject to legal retention requirements.</li>
            </ul>
            
            <h3>5. Data Security</h3>
            <p>We implement industry-standard technical and organizational measures to protect your information:</p>
            <ul>
                <li><strong>Encryption:</strong> We use encryption in transit (TLS/SSL) and at rest to protect your data from unauthorized access.</li>
                <li><strong>Access Controls:</strong> We limit access to your personal information to authorized employees, contractors, and service providers who need it to perform their duties.</li>
                <li><strong>Security Monitoring:</strong> We monitor our systems for security vulnerabilities, threats, and unauthorized access attempts.</li>
                <li><strong>Regular Audits:</strong> We conduct regular security assessments and audits to identify and address potential vulnerabilities.</li>
            </ul>
            <p><strong>However, no method of transmission over the internet or electronic storage is 100% secure.</strong> While we strive to protect your information, we cannot guarantee absolute security. You use our service at your own risk, and you are responsible for taking appropriate measures to protect your account credentials.</p>
            
            <h3>6. Your Privacy Rights & Choices</h3>
            <p>Depending on your location, you may have certain rights regarding your personal information:</p>
            
            <p><strong>6.1 General Rights (All Users):</strong></p>
            <ul>
                <li><strong>Access:</strong> Request access to the personal information we hold about you.</li>
                <li><strong>Correction:</strong> Request correction of inaccurate or incomplete information.</li>
                <li><strong>Deletion:</strong> Request deletion of your account and associated data.</li>
                <li><strong>Export:</strong> Request a copy of your data in a portable format.</li>
                <li><strong>Opt-Out:</strong> Opt out of marketing communications, push notifications, or certain data processing activities through in-app settings or by contacting us.</li>
            </ul>
            
            <p><strong>6.2 Additional Rights (EU/EEA, UK, California, and Similar Jurisdictions):</strong></p>
            <ul>
                <li><strong>Right to Object:</strong> Object to processing of your personal information for certain purposes, such as direct marketing or legitimate interests.</li>
                <li><strong>Right to Restrict Processing:</strong> Request restriction of processing in certain circumstances.</li>
                <li><strong>Right to Data Portability:</strong> Receive your data in a structured, commonly used, machine-readable format.</li>
                <li><strong>Right to Withdraw Consent:</strong> Withdraw consent for processing based on consent at any time.</li>
                <li><strong>Right to Non-Discrimination:</strong> Exercise your privacy rights without discrimination (California residents).</li>
                <li><strong>Right to Know:</strong> Know what personal information we collect, use, disclose, and sell (California residents).</li>
            </ul>
            
            <p>To exercise these rights, contact us at hello@codeai.studio or use the in-app settings. We will respond to your request within 30 days (or as required by applicable law). We may need to verify your identity before processing your request.</p>
            
            <h3>7. Children's Privacy</h3>
            <p>EverWith is not intended for children under 13 years of age (or the minimum age in your jurisdiction). We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately. If we become aware that we have collected personal information from a child under 13, we will take steps to delete such information promptly.</p>
            
            <h3>8. International Data Transfers</h3>
            <p>Your information may be transferred to, stored, and processed in countries other than your country of residence, including the United States, where our servers and service providers are located. These countries may have data protection laws that differ from those in your country.</p>
            <p>When we transfer your information internationally, we implement appropriate safeguards, including:</p>
            <ul>
                <li>Standard Contractual Clauses approved by the European Commission or other regulatory authorities.</li>
                <li>Other legally recognized transfer mechanisms, such as adequacy decisions or binding corporate rules.</li>
            </ul>
            <p>By using our service, you consent to the transfer of your information to countries outside your country of residence.</p>
            
            <h3>9. Cookies & Tracking Technologies</h3>
            <p>We use cookies, web beacons, pixel tags, and similar technologies to:</p>
            <ul>
                <li>Remember your preferences and settings.</li>
                <li>Authenticate your identity and maintain your session.</li>
                <li>Analyze usage patterns and improve our service.</li>
                <li>Provide personalized content and features.</li>
            </ul>
            <p>You can control cookies through your browser settings. However, disabling cookies may limit your ability to use certain features of our service.</p>
            <p>We do not use cookies or tracking technologies for third-party advertising purposes. We do not participate in cross-site tracking or sell your information to advertisers.</p>
            
            <h3>10. Third-Party Links & Services</h3>
            <p>Our service may contain links to third-party websites, services, or applications. We are not responsible for the privacy practices of these third parties. We encourage you to review their privacy policies before providing any information to them.</p>
            
            <h3>11. Changes to This Privacy Policy</h3>
            <p>We may update this Privacy Policy from time to time to reflect changes in our practices, technology, legal requirements, or for other reasons. We will notify you of material changes by:</p>
            <ul>
                <li>Posting the updated policy on this page with a new "Last Updated" date.</li>
                <li>Sending you an email notification (if you have provided an email address).</li>
                <li>Displaying an in-app notification or banner.</li>
            </ul>
            <p>Your continued use of the service after changes become effective constitutes acceptance of the updated Privacy Policy. If you do not agree to the changes, you should stop using the service and delete your account.</p>
            
            <h3>12. Do Not Track Signals</h3>
            <p>Some browsers offer a "Do Not Track" (DNT) feature that signals your preference not to be tracked online. We do not currently respond to DNT signals because there is no industry standard for how to respond to them. We will continue to monitor developments in this area.</p>
            
            <h3>13. California Privacy Rights (CCPA/CPRA)</h3>
            <p>If you are a California resident, you have additional rights under the California Consumer Privacy Act (CCPA) and California Privacy Rights Act (CPRA):</p>
            <ul>
                <li><strong>Right to Know:</strong> You have the right to know what personal information we collect, use, disclose, and sell.</li>
                <li><strong>Right to Delete:</strong> You have the right to request deletion of your personal information.</li>
                <li><strong>Right to Opt-Out:</strong> You have the right to opt-out of the sale of your personal information (we do not sell personal information).</li>
                <li><strong>Right to Non-Discrimination:</strong> We will not discriminate against you for exercising your privacy rights.</li>
                <li><strong>Right to Correct:</strong> You have the right to request correction of inaccurate personal information.</li>
            </ul>
            <p>To exercise these rights, contact us at hello@codeai.studio or use the in-app settings.</p>
            
            <h3>14. European Privacy Rights (GDPR)</h3>
            <p>If you are located in the European Economic Area (EEA), United Kingdom, or Switzerland, you have additional rights under the General Data Protection Regulation (GDPR):</p>
            <ul>
                <li><strong>Right of Access:</strong> You have the right to access your personal data and receive a copy of it.</li>
                <li><strong>Right to Rectification:</strong> You have the right to have inaccurate personal data corrected.</li>
                <li><strong>Right to Erasure:</strong> You have the right to request deletion of your personal data ("right to be forgotten").</li>
                <li><strong>Right to Restrict Processing:</strong> You have the right to restrict processing of your personal data in certain circumstances.</li>
                <li><strong>Right to Data Portability:</strong> You have the right to receive your personal data in a structured, commonly used format.</li>
                <li><strong>Right to Object:</strong> You have the right to object to processing of your personal data for certain purposes.</li>
                <li><strong>Right to Withdraw Consent:</strong> You have the right to withdraw consent for processing based on consent.</li>
                <li><strong>Right to Lodge a Complaint:</strong> You have the right to lodge a complaint with your local data protection authority.</li>
            </ul>
            <p>To exercise these rights, contact us at hello@codeai.studio. Our legal basis for processing your personal data includes: (1) your consent, (2) performance of a contract, (3) compliance with legal obligations, (4) protection of vital interests, (5) performance of a task in the public interest, and (6) legitimate interests.</p>
            
            <h3>15. Contact Us</h3>
            <p>If you have questions, concerns, or requests regarding this Privacy Policy or our data practices, please contact us:</p>
            <ul>
                <li><strong>Email:</strong> <a href="mailto:hello@codeai.studio">hello@codeai.studio</a></li>
                <li><strong>Data Protection Officer (EU):</strong> hello@codeai.studio</li>
            </ul>
            <p>We will respond to your inquiry within 30 days (or as required by applicable law).</p>
        </section>

        <footer>
            EverWith © {LAST_UPDATED.split(',')[-1].strip()} • Contact hello@codeai.studio for escalation
        </footer>
    </main>
</body>
</html>
    """


@router.get("/legal", response_class=HTMLResponse)
async def legal_portal(section: str | None = Query(default=None, alias="section")):
    return HTMLResponse(content=_render_legal_page(section or "terms"))


@router.get("/legal/terms", response_class=HTMLResponse)
async def legal_terms():
    return HTMLResponse(content=_render_legal_page("terms"))


@router.get("/legal/privacy", response_class=HTMLResponse)
async def legal_privacy():
    return HTMLResponse(content=_render_legal_page("privacy"))

